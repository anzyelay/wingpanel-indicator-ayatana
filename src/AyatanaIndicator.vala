/*
 * Copyright (c) 2011-2015 Wingpanel Developers (http://launchpad.net/wingpanel)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

public class AyatanaCompatibility.Indicator : Wingpanel.Indicator {
    private IndicatorButton icon;

    private Gtk.Stack main_stack;
    private Gtk.Grid main_grid;

    private unowned IndicatorAyatana.ObjectEntry entry;
    private unowned IndicatorAyatana.Object parent_object;
    private IndicatorIface indicator;
    private string entry_name_hint;

    private Gee.HashMap<Gtk.Widget, Gtk.Widget> menu_map;

    const int MAX_ICON_SIZE = 24;

    public Indicator (IndicatorAyatana.ObjectEntry entry, IndicatorAyatana.Object obj, IndicatorIface indicator) {
        Object (code_name: "%s%s".printf ("ayatana-", entry.name_hint),
                display_name: "%s%s".printf ("ayatana-", entry.name_hint),
                description: _("Ayatana compatibility indicator"));
        this.entry = entry;
        this.indicator = indicator;
        this.parent_object = obj;
        this.menu_map = new Gee.HashMap<Gtk.Widget, Gtk.Widget> ();

        unowned string name_hint = entry.name_hint;

        if (name_hint == null) {
            warning ("NULL name hint");
        }

        entry_name_hint = name_hint != null ? name_hint.dup () : "";

        if (entry.menu == null) {
            critical ("Indicator: %s has no menu widget.", entry_name_hint);

            return;
        }

        /*
         * Workaround for buggy indicators: this menu may still be part of
         * another panel entry which hasn't been destroyed yet. Those indicators
         * trigger entry-removed after entry-added, which means that the previous
         * parent is still in the panel when the new one is added.
         */
        if (entry.menu.get_attach_widget () != null) {
            entry.menu.detach ();
        }

        this.visible = true;
    }

    public override Gtk.Widget get_display_widget () {
        if (icon == null) {
            icon = new IndicatorButton ();

            var image = entry.image as Gtk.Image;

            if (image != null) {
                /*
                 * images holding pixbufs are quite frequently way too large, so we whenever a pixbuf
                 * is assigned to an image we need to check whether this pixbuf is within reasonable size
                 */
                if (image.storage_type == Gtk.ImageType.PIXBUF) {
                    image.notify["pixbuf"].connect (() => {
                        ensure_max_size (image);
                    });

                    ensure_max_size (image);
                }

                image.pixel_size = MAX_ICON_SIZE;

                icon.set_widget (IndicatorButton.WidgetSlot.IMAGE, image);
            }

            var label = entry.label;

            if (label != null && label is Gtk.Label) {
                icon.set_widget (IndicatorButton.WidgetSlot.LABEL, label);
            }

            icon.scroll_event.connect (on_scroll);
            icon.button_press_event.connect (on_button_press);
        }

        return icon;
    }

    public string name_hint () {
        return entry_name_hint;
    }

    public bool on_button_press (Gdk.EventButton event) {
        if (event.button == Gdk.BUTTON_MIDDLE) {
            parent_object.secondary_activate (entry, event.time);

            return Gdk.EVENT_STOP;
        }

        return Gdk.EVENT_PROPAGATE;
    }

    public bool on_scroll (Gdk.EventScroll event) {
        parent_object.entry_scrolled (entry, 1, (IndicatorAyatana.ScrollDirection)event.direction);

        return Gdk.EVENT_PROPAGATE;
    }

    int position = 0;
    public override Gtk.Widget? get_widget () {
        if (main_stack == null) {
            bool reloaded = false;
            icon.parent.parent.enter_notify_event.connect ((w, e) => {
                if (!reloaded) {
                    /*
                     * workaround for indicators (e.g. dropbox) that only update menu children after
                     * the menu is popuped
                     */
                    reloaded = true;
                    entry.menu.popup (null, null, null, 0, Gtk.get_current_event_time ());
                    entry.menu.popdown ();
                }

                return Gdk.EVENT_PROPAGATE;
            });

            main_stack = new Gtk.Stack ();
            main_stack.map.connect (() => {
                main_stack.set_visible_child (main_grid);
                reloaded = false;
            });
            main_grid = new Gtk.Grid ();
            main_stack.add (main_grid);

            foreach (var item in entry.menu.get_children ()) {
                on_menu_widget_insert (item);
            }

            entry.menu.insert.connect (on_menu_widget_insert);
            entry.menu.remove.connect (on_menu_widget_remove);
        }

        return main_stack;
    }

    private void on_menu_widget_insert (Gtk.Widget item) {
        var w = convert_menu_widget (item);

        if (w != null) {
            menu_map.set (item, w);
            main_grid.attach (w, 0, position++, 1, 1);
            w.show ();
        }
    }

    private void on_menu_widget_remove (Gtk.Widget item) {
        var w = menu_map.get (item);

        if (w != null) {
            main_grid.remove (w);
            menu_map.unset (item);
        }
    }

    private Gtk.Image? check_for_image (Gtk.Container container) {
        foreach (var c in container.get_children ()) {
            if (c is Gtk.Image) {
                return (c as Gtk.Image);
            } else if (c is Gtk.Container) {
                return check_for_image ((c as Gtk.Container));
            }
        }

        return null;
    }

    /* convert the menuitems to widgets that can be shown in popovers */
    private Gtk.Widget? convert_menu_widget (Gtk.Widget item) {
        /* menuitem not visible */
        if (!item.get_visible ()) {
            return null;
        }

        /* seperator are GTK.SeparatorMenuItem, return a separator */
        if (item is Gtk.SeparatorMenuItem) {
            return new Wingpanel.Widgets.Separator ();
        }

        /* all other items are genericmenuitems */
        string label = (item as Gtk.MenuItem).get_label ();
        label = label.replace ("_", "");

        /*
         * get item type from atk accessibility
         * 34 = MENU_ITEM  8 = CHECKBOX  32 = SUBMENU 44 = RADIO
         */
        var atk = item.get_accessible ();
        Value val = Value (typeof (int));
        atk.get_property ("accessible_role", ref val);
        var item_type = val.get_int ();

        var sensitive = item.get_sensitive ();
        var active = (item as Gtk.CheckMenuItem).get_active ();

        /* detect if it has a image */
        Gtk.Image? image = null;
        var child = (item as Gtk.Bin).get_child ();

        if (child != null) {
            if (child is Gtk.Image) {
                image = (child as Gtk.Image);
            } else if (child is Gtk.Container) {
                image = check_for_image ((child as Gtk.Container));
            }
        }

        if (item_type == 8) {
            var button = new Wingpanel.Widgets.Switch (label, active);
            button.get_switch ().state_set.connect ((b) => {
                (item as Gtk.CheckMenuItem).set_active (b);
                close ();

                return false;
            });

            return button;
        }

        /* convert menuitem to a indicatorbutton */
        if (item is Gtk.MenuItem) {
            Gtk.Button button;

            if (image != null && image.pixbuf == null && image.icon_name != null) {
                try {
                    Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();
                    image.pixbuf = icon_theme.load_icon (image.icon_name, 16, 0);
                } catch (Error e) {
                    warning (e.message);
                }
            }

            if (image != null && image.pixbuf != null) {
                button = new Wingpanel.Widgets.Button (label);
                (button as Wingpanel.Widgets.Button).set_pixbuf (image.pixbuf);
            } else {
                button = new Wingpanel.Widgets.Button (label);
            }

            button.set_sensitive (sensitive);

            if (sensitive) {
                var submenu = (item as Gtk.MenuItem).submenu;

                if (submenu != null) {
                    int pos = 0;
                    var scroll_sub = new Gtk.ScrolledWindow (null, null);
                    scroll_sub.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
                    var sub_stack = new Gtk.Grid ();
                    scroll_sub.add (sub_stack);
                    var w = new Wingpanel.Widgets.Button (_("Back"));
                    w.clicked.connect (() => {
                        main_stack.set_visible_child (main_grid);
                    });
                    sub_stack.attach (w, 0, pos++, 1, 1);
                    sub_stack.attach (new Wingpanel.Widgets.Separator (), 0, pos++, 1, 1);
                    submenu.popup (null, null, null, 0, Gtk.get_current_event_time ());
                    submenu.insert.connect ((sub_item) => {
                        var sub_menu_item = convert_menu_widget (sub_item);

                        if (sub_menu_item != null) {
                            sub_stack.attach (sub_menu_item, 0, pos++, 1, 1);
                        }
                    });
                    submenu.popdown ();
                    main_stack.add (scroll_sub);
                    button = new SubMenuButton (label);
                    button.clicked.connect (() => {
                        main_stack.set_visible_child (scroll_sub);
                        main_stack.show_all ();
                    });
                } else {
                    button.clicked.connect (() => {
                        close ();
                        item.activate ();
                    });
                }
            }

            return button;
        }

        return null;
    }

    public override void opened () {
    }

    public override void closed () {
    }

    private void ensure_max_size (Gtk.Image image) {
        var pixbuf = image.pixbuf;

        if (pixbuf != null && pixbuf.get_height () > MAX_ICON_SIZE) {
            image.pixbuf = pixbuf.scale_simple ((int)((double)MAX_ICON_SIZE / pixbuf.get_height () * pixbuf.get_width ()),
                                                MAX_ICON_SIZE, Gdk.InterpType.HYPER);
        }
    }
}