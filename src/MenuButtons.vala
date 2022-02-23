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
namespace AyatanaCompatibility {
    const string button_css = """
        button {
            border-radius: 4px;
            font-size: 16px;
        }
        button:hover:not(.checked){
            background: rgba(0, 0, 0, 0.1);
        }
        button:active,
        .checked {
            background: rgba(38, 138, 255, 1);
        }
        """;
    const string grid_css = """
        grid {
            background-color: rgba(255, 255, 255, 0.92);
            border-radius: 6px;
            box-shadow: inset 0 20px 30px -1px rgba(0, 0, 0, 0.1);
            padding: 4px;
        }
    """;
    public class MenuButton : Gtk.Button {
        private Gtk.Label ?_label = null;
        private Gtk.Image _image;
        private Gtk.ArrowType _image_direction; 
        public Gtk.ArrowType image_direction {
            set {
                _image_direction = value;
                switch (_image_direction) {
                    case Gtk.ArrowType.UP:
                        _image.icon_name = "pan-up-symbolic";
                        break;
                    case Gtk.ArrowType.LEFT: {
                        _image.icon_name = "pan-start-symbolic";
                        break;
                    }
                    case Gtk.ArrowType.DOWN:
                        _image.icon_name = "pan-down-symbolic";
                        break;
                    case Gtk.ArrowType.RIGHT:
                        _image.icon_name = "pan-end-symbolic";
                        break;
                    default: {
                        _image.icon_name = "";
                        break;
                    }
                }
            }
            get {
                return _image_direction;
            }
        } 
        public new unowned string ?label {
            set {
                _label.label = (value);
            }
            get {
                return _label.label;
            }
        }

        public new Gtk.Image image {
            set {
                if (value.storage_type == Gtk.ImageType.PIXBUF) {
                    _image.pixbuf = value.pixbuf;
                    value.notify["pixbuf"].connect (()=>{
                        _image.pixbuf = value.pixbuf;
                    });
                }
                else if (value.storage_type == Gtk.ImageType.ICON_NAME) {
                    try {
                        _image.pixbuf = Gtk.IconTheme.get_default ().load_icon (value.icon_name, 16, 0);
                    } catch (Error e) {}
                    value.notify["icon-name"].connect ((e)=>{
                        if (value.icon_name == null) {
                            return ;
                        }
                        try {
                            _image.pixbuf = Gtk.IconTheme.get_default ().load_icon (value.icon_name, 16, 0);
                        } catch (Error e) {
                            warning (e.message);
                        }
                    });
                }
                else {
                    _image = value;
                }
            }
            get {
                return _image;
            }
        }

        construct {
            var style_context = get_style_context ();
            style_context.add_class ("flat");

            //TODO make sure with hh about the label font size 
            Gtk.CssProvider provider = new Gtk.CssProvider();
            try {
                provider.load_from_data (button_css, button_css.length);
            } catch (GLib.Error err) {
                warning ("load css data failure:%s", err.message);
                return;
            }
            style_context.add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        }

        public MenuButton (string label, Gtk.ArrowType arrow_type = Gtk.ArrowType.NONE) {
            hexpand = true;

            _label = new Gtk.Label (label);

            _image = new Gtk.Image ();
            _image.halign = Gtk.Align.END;
            _image.hexpand = true;
            image_direction = arrow_type;

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
                hexpand = true,
                halign = Gtk.Align.FILL,
                margin = 0
            };
            box.add (_label);
            box.add (_image);

            add (box);
            show_all ();

            _image.notify["pixbuf"].connect ( ()=>{
                if (_image.pixbuf == null) {
                    return;
                } 
                const int max_icon_size = 16;
                var pixbuf = _image.pixbuf;
                if (pixbuf != null && pixbuf.get_height () > max_icon_size) {
                    _image.pixbuf = pixbuf.scale_simple (
                        (int)((double)max_icon_size / pixbuf.get_height () * pixbuf.get_width ()),
                        max_icon_size, Gdk.InterpType.HYPER);
                }
            });
        }

    }
    public class ToggleButton : MenuButton {
        //  public abstract bool check { set; get; }
        public signal void toggled ();
        private bool _checked = false;
        public virtual bool checked { 
            get { return _checked; }
            set {
                _checked = value;
                if (value) {
                    get_style_context ().add_class ("checked");
                } 
                else {
                    get_style_context ().remove_class ("checked");
                }
            }
        }
        
        construct {
            clicked.connect (toggle);
        }

        public ToggleButton (string label) {
            base (label);
        }

        public virtual void toggle () {
            toggled ();
            checked = !checked;
        }

    }
    public class CheckButton : ToggleButton {
        public CheckButton (string label) {
            base (label);
        }
        public CheckButton.with_checked (string label, bool checked) {
            base (label);
            this.checked = checked;
        }
    }

    public class RadioButton : ToggleButton {
        private RadioButton ?_current_selected=null;
        private RadioButton _group;
        public RadioButton group  {
            set {
                _group = value!=null ? value : this;
            }
            get {
                return _group!=null ? _group : this;
            }
        }
        public RadioButton ?current_selected {
            get {
                return group._current_selected;
            }
            set {
                group._current_selected = value;
            }
        }
    
        public RadioButton (string label, RadioButton ?group = null) {
            base (label);
            this.group = group;
        }

        private void alter_selected_button () {
            if ( current_selected!=null && this!=current_selected ) {
                // change last selected button's checked status
                current_selected.checked = false;
            }
            current_selected = this;
        }

        public override void toggle () {
            if (!checked) {
                alter_selected_button ();
                checked = true;
            }
        }
    }

    public class Separator : Gtk.Separator {
        public Separator () {
            orientation = Gtk.Orientation.HORIZONTAL;
            margin_top = 4;
            margin_bottom = 4;
            margin_start = 6;
            margin_end = 6;
        }
    }
    
    public class MenuGrid : Gtk.Grid {
        construct {
            orientation = Gtk.Orientation.VERTICAL;
            expand = true;
            valign = Gtk.Align.START;
            var style_context = get_style_context ();

            //TODO make sure with hh about the label font size 
            Gtk.CssProvider provider = new Gtk.CssProvider();
            try {
                provider.load_from_data (grid_css, grid_css.length);
            } catch (GLib.Error err) {
                warning ("load css data failure:%s", err.message);
                return;
            }
            style_context.add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        }
    }
}
