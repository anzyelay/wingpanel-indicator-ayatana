/*-
 * Copyright (c) 2015 Wingpanel Developers (http://launchpad.net/wingpanel)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class AyatanaCompatibility.IndicatorButton : Gtk.Box {
    const int MAX_ICON_SIZE = 20;

    private Gtk.Label the_label;
    private Gtk.Image the_image;

    public IndicatorButton (string ?name = null) {
        this.name = name;
        set_orientation (Gtk.Orientation.HORIZONTAL);
        set_homogeneous (false);

        // Fix padding.
        Gtk.StyleContext style = get_style_context ();
        Gtk.CssProvider provider = new Gtk.CssProvider ();
		//catch GLib error
		try {
			provider.load_from_data (".ayatana-indicator { padding: 0px; }");
		} catch (Error e) {
                warning (e.message);
        }
        style.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        style.add_class ("ayatana-indicator");
    }

    private void ensure_max_size (Gtk.Image image) {
        var pixbuf = image.pixbuf;

        if (pixbuf != null && pixbuf.get_height () > MAX_ICON_SIZE) {
			//scale_simple(dest_width,dest_height,interp)
            image.pixbuf = pixbuf.scale_simple (
                (int)((double)MAX_ICON_SIZE / pixbuf.get_height () * pixbuf.get_width ()),
            	MAX_ICON_SIZE, Gdk.InterpType.HYPER);
        }
    }

    public void set_image (Gtk.Image ?image) {
        if (the_image != null) {
            remove (the_image);
            the_image.get_style_context ().remove_class ("composited-indicator");
        }
        if (image == null) {
            return;
        }

        // Workaround for buggy indicators: Some widgets may still be part of a previous entry
        // if their old parent hasn't been removed from the panel yet.
        var parent = image.parent;
        if (parent != null) {
            parent.remove (image);
        }
        image.get_style_context ().add_class ("composited-indicator");
        /*
        * images holding pixbufs are quite frequently way too large, so we whenever a pixbuf
        * is assigned to an image we need to check whether this pixbuf is within reasonable size
        */
        if (image.storage_type == Gtk.ImageType.PIXBUF ) {
            image.notify["pixbuf"].connect (() => {
                ensure_max_size (image);
            });
            ensure_max_size (image);
        }
        image.pixel_size = MAX_ICON_SIZE;

        the_image = image;
        pack_start (the_image, false, false, 0);

    }

    public void set_label (Gtk.Label ?label) {
        if (the_label != null) {
            remove (the_label);
            the_label.get_style_context ().remove_class ("composited-indicator");
        }
        if (label == null) {
            return;
        }

        // Workaround for buggy indicators: Some widgets may still be part of a previous entry
        // if their old parent hasn't been removed from the panel yet.
        var parent = label.parent;
        if (parent != null)
            parent.remove (label);

        label.get_style_context ().add_class ("composited-indicator");

        the_label = label;
        pack_end (the_label, false, false, 0);
    }
}


