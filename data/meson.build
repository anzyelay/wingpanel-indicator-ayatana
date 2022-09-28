i18n.merge_file(
    input: 'my.gschema.xml.in',
    output: meson.project_name () + '.gschema.xml',
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    install_dir: join_paths (get_option('datadir'), 'glib-2.0', 'schemas'),
    install: true
)
