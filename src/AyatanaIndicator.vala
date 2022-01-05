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

    private unowned IndicatorAyatana.ObjectEntry entry;
    private unowned IndicatorAyatana.Object parent_object;
    private IndicatorIface indicator;
    private string entry_name_hint;
    const int MAX_ICON_SIZE = 20;
    private Gtk.Grid ?main_widget = null;
    
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

        entry.menu.enter_notify_event.connect( (e)=>{
            Gtk.grab_remove(entry.menu);
            return Gdk.EVENT_PROPAGATE;
        });
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

        return Gdk.EVENT_PROPAGATE;
    }

    public bool on_scroll (Gdk.EventScroll event) {
        parent_object.entry_scrolled (entry, 1, (IndicatorAyatana.ScrollDirection)event.direction);

        return Gdk.EVENT_PROPAGATE;
    }

    public override Gtk.Widget? get_widget () {
        return entry.menu;
        //  if (main_widget == null) {
        //      main_widget = new Gtk.Grid ();
        //      main_widget.add (entry.menu);
        //      main_widget.map.connect (()=>{
        //          entry.menu.rect_anchor_dy = 40;
        //          entry.menu.popup_at_widget (icon.parent, Gdk.Gravity.CENTER, Gdk.Gravity.CENTER, Gtk.get_current_event ());
        //      });
        //      main_widget.unmap.connect (()=>{
        //          entry.menu.popdown ();
        //      });
        //  }
        //  return main_widget;
    }

    public override void opened () {
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
