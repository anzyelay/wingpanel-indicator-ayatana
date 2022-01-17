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
 * Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

public class AyatanaCompatibility.Indicator : Wingpanel.Indicator {
    private IndicatorButton icon;

    private Gtk.Stack main_stack;
    private Wingpanel.IndicatorGrid main_grid;

    private unowned IndicatorAyatana.ObjectEntry entry;
    private unowned IndicatorAyatana.Object parent_object;
    private IndicatorIface indicator;
    private string entry_name_hint;
    private bool entry_is_null = false;

    //maps to help dynamic changes in menus and submenus
    private Gee.HashMap<Gtk.Widget, Gtk.Widget> menu_map;
	
    const int MAX_ICON_SIZE = 20;
    
	//grouping radio buttons
	private RadioButton? group_radio=null ;
	
    public Indicator (IndicatorAyatana.ObjectEntry entry, IndicatorAyatana.Object obj, IndicatorIface indicator) {
        string name_hint = entry.name_hint;
        if (name_hint == null) {
            var current_time = new DateTime.now_local ();
            name_hint = current_time.hash ().to_string ();
        }

        Object (code_name: "%s%s".printf ("ayatana-", name_hint));

        this.entry = entry;
        this.indicator = indicator;
        this.parent_object = obj;
        this.menu_map = new Gee.HashMap<Gtk.Widget, Gtk.Widget> ();
        entry_name_hint = name_hint;

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
		//show an icon in the panel
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
        else if (event.button == Gdk.BUTTON_PRIMARY) {
            entry.parent_object.entry_activate (entry, event.time);
            return Gdk.EVENT_STOP;
        }

        //  else if (event.button == Gdk.BUTTON_SECONDARY) {
        //      entry.menu.popup_at_widget(icon.parent,0,0);
        //      return Gdk.EVENT_STOP;
        //  }

        return Gdk.EVENT_PROPAGATE;
    }

    public bool on_scroll (Gdk.EventScroll event) {
        parent_object.entry_scrolled (entry, 1, (IndicatorAyatana.ScrollDirection)event.direction);

        return Gdk.EVENT_PROPAGATE;
    }
    
    public void clear_entry () {
        entry_is_null = true;
    }

    private void update_entry_menu () {
        if (!entry_is_null) {
            entry.menu.popup_at_widget(icon.parent,0,0);
            entry.menu.popdown ();
        }
        else {
            close ();
        }
    }

    public override Gtk.Widget? get_widget () {
        if (main_stack == null) {
            bool reloaded = false;
            icon.parent.parent.enter_notify_event.connect ((w, e) => {
                if (!reloaded && e.mode != Gdk.CrossingMode.TOUCH_BEGIN) {
                    /*
                     * workaround for indicators (e.g. dropbox) that only update menu children after
                     * the menu is popuped
                     */
                    reloaded = true;
                    //show underlying menu (debug)
                    update_entry_menu ();
                }

                return Gdk.EVENT_PROPAGATE;
            });

            main_stack = new Gtk.Stack () {
                vhomogeneous = false
            };
            main_grid = new Wingpanel.IndicatorGrid () {
                valign = Gtk.Align.START
            };
            menu_layout_parse (entry.menu, main_grid, menu_map);
            main_stack.add (main_grid);
            main_stack.show_all();

            main_stack.map.connect (() => {
				//reload: open first on main_list
                main_stack.set_visible_child (main_grid);
                reloaded = false;
            });
            main_stack.unmap.connect (()=>{
                //make sure right height when show again
                alter_display_page (main_grid);
            });
        }

        return main_stack;
    }

    private void menu_layout_parse (Gtk.Menu menu, 
                                        Gtk.Container container=main_grid,
                                        Gee.HashMap<Gtk.Widget, Gtk.Widget> hashmap=menu_map) {
        foreach (var item in menu.get_children ()) {
            on_menu_widget_insert (item, container, hashmap);
        }

        menu.insert.connect ((e)=>{
            on_menu_widget_insert (e, container, hashmap);
        });
        menu.remove.connect ( (e)=>{
            on_menu_widget_remove (e, container, hashmap);
        });
    }

    private void on_menu_widget_insert (Gtk.Widget item,
                                        Gtk.Container container,
                                        Gee.HashMap<Gtk.Widget, Gtk.Widget>  hashmap) {
        if (hashmap.get (item)!=null) {
            warning ("has been inserted before");
            return;
        }
        var w = convert_menu_widget (item, container);
        if (w != null) {
            container.add (w);
            hashmap.set (item, w);
            /* menuitem not visible */
            if (!item.get_visible ()) {
                w.no_show_all = true;
                w.hide ();
            } else {
                w.show ();
            }
            //  warning ("insert %s", ((Gtk.MenuItem)item).label);
        }
    }

    private void on_menu_widget_remove (Gtk.Widget item, 
                                        Gtk.Container container,
                                        Gee.HashMap<Gtk.Widget, Gtk.Widget>  hashmap) {
        var w = hashmap.get (item);

        if (w != null) {
            //  warning ("------------remove a item: %s --> widget: %s", ((Gtk.MenuItem)item).get_label (), w.get_type ().name ());
            container.remove (w);
            hashmap.unset (item);
            w.destroy ();
        }
        else {
            warning ("the removing item (%s) are not found!!", ((Gtk.MenuItem)item).get_label ());
        }
    }

    private Gtk.Image? check_for_image (Gtk.Widget widget) {
        if (widget is Gtk.Image) {
            return widget as Gtk.Image;
        }
        else if (widget is Gtk.Container) {
            foreach (var c in ((Gtk.Container)widget).get_children ()) {
                var image = check_for_image (c);
                if (image != null)
                    return image;
            }
        }
        return null;
    }

    private void connect_signals (Gtk.Widget item, Gtk.Widget button) {
        item.show.connect (() => {
            button.no_show_all = false;
            button.show ();
        });
        item.hide.connect (() => {
            button.no_show_all = true;
            button.hide ();
        });
		item.state_flags_changed.connect ((type) => {
           button.set_state_flags (item.get_state_flags (),true);
        });
        if (item is Gtk.MenuItem) {
            ((Gtk.MenuItem)item).notify["label"].connect (() => {
                var label = ((Gtk.MenuItem)item).get_label ().replace ("_", "");
                if ( button is MenuButton ) {
                    ((MenuButton)button).label = label;
                }
                else {
                    warning ("========label should be changed to %s=========", label);
                }
            });
        }
    }

    /* convert the menuitems to widgets that can be shown in popovers */
    private Gtk.Widget? convert_menu_widget (Gtk.Widget widget, Gtk.Container container) {
        var item = widget as Gtk.MenuItem;
        if (item == null) {
            warning ("not a menu item type");
			group_radio = null; 
            return null;
        }

        /* separator are GTK.SeparatorMenuItem, return a separator */
        if (item is Gtk.SeparatorMenuItem) {
			group_radio = null; 
            var separator =  new Separator ();
            connect_signals (item, separator);
            return separator;
        }

        /* all other items are genericmenuitems 
         *   get item type from atk accessibility
         *   CHECK_MENU_ITEM==Atk.Role.for_name ("check menu item"):checkmenuitem
         *   RADIO_MENU_ITEM==Atk.Role.for_name ("radio menu item"):radiomenuitem
         *   MENU_ITEM==Atk.Role.for_name ("menu item"):menuitem
         *   MENU==Atk.Role.for_name ("menu"):submenu
         *   
         */
		string label = item.get_label ();
    	label = label.replace ("_", "");
        var state = item.get_state_flags ();
        var atk = item.get_accessible ();
        Value val = Value (typeof (int));
        atk.get_property ("accessible_role", ref val);
        var item_role = (Atk.Role)val.get_int ();
        if (item_role != Atk.Role.RADIO_MENU_ITEM) {
            group_radio = null;
        } 

        //  warning ("%s   %s    %d", item.get_type ().name (), item_role.get_name (), item_role);
        MenuButton ?new_button = null;

        if (item_role == Atk.Role.CHECK_MENU_ITEM ) {
            //  warning ("is check menu item");
            var button = new CheckButton (label);
            var check = item as Gtk.CheckMenuItem;
            if (check != null) {
                if (check.active) {
                    button.checked = check.active;
                }
            }
            new_button = button;
        }
        else if (item_role == Atk.Role.MENU_ITEM) {
            //  warning ("%s  -- is menu item", label); 
            var button = new MenuButton (label);
            new_button = button;
        }
        else if (item_role == Atk.Role.RADIO_MENU_ITEM) {
            //  warning ("is radio menu item"); cant convert to radiomenuitem
            var button = new RadioButton (label, group_radio);
            if (group_radio == null) {
                group_radio = button;
            }
            var check = item as Gtk.CheckMenuItem;
            if (check != null) {
                if (check.active) {
                    button.toggle ();
                }
            }
            new_button = button;
        }
        else if (item_role == Atk.Role.MENU) {
            //  warning ("is sub menu item");
            var submenu = ((Gtk.MenuItem)item).submenu;
            if (submenu!=null) {
                var child_grid = new Wingpanel.IndicatorGrid () {
                    valign = Gtk.Align.START
                };
                //back btn
				var btn_back = new MenuButton (_("BACK"), Gtk.ArrowType.LEFT);
				btn_back.clicked.connect(()=>{
                    alter_display_page (container);
				});
				child_grid.add (btn_back);
				child_grid.add (new Separator ());
                //convert
                menu_layout_parse (submenu, child_grid, menu_map);

                main_stack.add (child_grid);
                
                //forward btn
                var button = new MenuButton (label, Gtk.ArrowType.RIGHT);
                button.set_state_flags (state, true);
                button.clicked.connect (() => {
                    //  item.activate ();
                    alter_display_page (child_grid);
                });
                connect_signals (item, button);
                return button;
            }
        }
        else {
            warning ("item role is :%d < -- >label:%s, type name:%s, role name:%s", 
                        item_role, label, 
                        item.get_type ().name (),
                        item_role.get_name ());
            return null;

        }
        /* detect if it has a image */
        Gtk.Image? image = null;
        var child = ((Gtk.Bin)item).get_child ();
        if (child != null) {
            image = check_for_image (child);
            if (image != null && image.pixbuf == null && image.icon_name != null) {
                try {
                    Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();
                    image.pixbuf = icon_theme.load_icon (image.icon_name, 16, 0);
                } catch (Error e) {
                    warning (e.message);
                }
            }
			if (image != null && image.pixbuf != null) {
				//  var img= new Gtk.Image.from_pixbuf(image.pixbuf);
                //  var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
                //  hbox.set_hexpand (true);
                //  hbox.set_vexpand (false);
                //  hbox.add(img);
                //  hbox.add(model_button);
                //  return hbox;
                //  model_button.icon = image.pixbuf;
            } 
        }

        new_button.set_state_flags (state, true);
        new_button.clicked.connect (()=>{
            item.activate ();
            GLib.Timeout.add (150, ()=>{
                update_entry_menu ();
                return false;
            });
            //  close ();
        });
        connect_signals (item, new_button);

        return new_button;
    }

    private void alter_display_page (Gtk.Widget page) {
        int width = main_stack.get_allocated_width ();
        int height = page.get_allocated_height ();
        main_stack.set_visible_child (page);
        main_stack.get_window ().resize (width, height);
        main_stack.show_all ();
    }
    public override void opened () {
        entry_is_null = false;
    }

    public override void closed () {
    }

    private void ensure_max_size (Gtk.Image image) {
        var pixbuf = image.pixbuf;

        if (pixbuf != null && pixbuf.get_height () != MAX_ICON_SIZE) {
			//scale_simple(dest_width,dest_height,interp)
            image.pixbuf = pixbuf.scale_simple (
                (int)((double)MAX_ICON_SIZE / pixbuf.get_height () * pixbuf.get_width ()),
            	MAX_ICON_SIZE, Gdk.InterpType.HYPER);
        }
    }
}
