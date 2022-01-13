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
        button box label {
            font-size: 16px;
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
                _image = value;
                //  try {
                    //  Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();
                    //  _image.pixbuf = icon_theme.load_icon (icon_name, 16, 0);
                //  } catch (Error e) {
                //      warning (e.message);
                //  }
            }
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
        }

        construct {
            var style_context = this.get_style_context ();
            style_context.add_class ("flat");

            //TODO make sure with hh about the label font size 
            Gtk.CssProvider provider = new Gtk.CssProvider();
            try {
                provider.load_from_data (button_css, button_css.length);
                style_context.add_provider(provider,
                                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                _label.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (GLib.Error err) {
                ;
            }

        }
    }
    public class ToggleButton : MenuButton {
        //  public abstract bool check { set; get; }
        public signal void toggled ();
        private bool _checked = false;
        public virtual bool check { 
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
        
        public ToggleButton (string label) {
            base (label);
        }

        construct {
            clicked.connect (on_toggle_event);
        }

        public virtual void on_toggle_event () {
            toggled ();
            check = !check;
        }

    }
    public class CheckButton : ToggleButton {
        public CheckButton (string label) {
            base (label);
        }
        public CheckButton.with_checked (string label, bool check) {
            base (label);
            this.check = check;
        }
    }

    public class RadioButton : ToggleButton {
        public override bool check {
            get { return base.check; }
            set {
                if (value) {
                    alter_selected_button ();
                }
                base.check = value;
            }
        }
        private RadioButton ?_group = null;
        public RadioButton group  {
            set {
                _group = value!=null ? value : this;
            }
            get {
                return _group;
            }
        }
        private RadioButton ?current_selected=null;
    
        public RadioButton (string label, RadioButton ?group = null) {
            base (label);
            this.group = group;
        }

        private void alter_selected_button () {
            if ( group.current_selected!=null && this!=group.current_selected ) {
                // change last selected button's status
                group.current_selected.check = false;
            }
            group.current_selected = this;
        }
    }
}
