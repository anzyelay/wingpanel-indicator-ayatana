# ----------------------------------------------------------------------------------------------------------------------
# Project: wingpanel-indicator-ayatana
#
# A Wingpanel indicator plug-in that adds ayatana indicator support.
# ----------------------------------------------------------------------------------------------------------------------
project('wingpanel-indicator-ayatana', 'vala', 'c')

sources = [
    'src/AyatanaIndicator.vala',
    'src/Indicator.vala',
    'src/IndicatorIcon.vala',
    'src/IndicatorFactory.vala',
    'src/IndicatorIface.vala',
    'src/IndicatorLoader.vala',
    'src/IndicatorObject.vala',
    'src/MenuButtons.vala',
]
 wingpanel= dependency('wingpanel-2.0',required : false)
 if not wingpanel.found()
      wingpanel = dependency('wingpanel',required : true)
    endif
dependencies = {
    'granite':    dependency('granite'),
    'indicator3': dependency('indicator3-0.4'),
    'wingpanel': wingpanel
}

libdir = join_paths(get_option('prefix'), get_option('libdir'))

indicator_name = 'ayatana'
indicator_dir  = dependencies['wingpanel'].get_pkgconfig_variable('indicatorsdir', define_variable: ['libdir', libdir])

# ----------------------------------------------------------------------------------------------------------------------
# Bindings:

add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
                      language: 'vala')

# ----------------------------------------------------------------------------------------------------------------------
# Internationalization:

i18n = import('i18n')
gettext_name = indicator_name + '-indicator'

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
                     language: 'c')
# ----------------------------------------------------------------------------------------------------------------------
# Generated conf_data:

conf_data = configuration_data()
conf_data.set_quoted('WINGPANEL_INDICATOR_DIR', join_paths(get_option('prefix'), indicator_dir))
conf_data.set_quoted('AYATANA_INDICATOR_DIR',   dependencies['indicator3'].get_pkgconfig_variable('indicatordir'))
conf_data.set_quoted('INDICATOR_NAME',          indicator_name)
conf_data.set_quoted('DATA_DIR',                join_paths(get_option('prefix'), get_option('datadir')))
conf_data.set_quoted('GETTEXT_PACKAGE',         gettext_name)
conf_data.set_quoted('LOCALEDIR',               join_paths(get_option('prefix'), get_option('localedir')))

conf_data_file = configure_file(
    input: 'src/Constants.vala.in',
    output: 'Constants.vala',
    configuration: conf_data
)

# ----------------------------------------------------------------------------------------------------------------------
# Build:

deps = []
foreach _,v : dependencies
    deps += v
endforeach

shared_module(
    indicator_name,

    sources,
    conf_data_file,

    dependencies: deps,

    install:     true,
    install_dir: indicator_dir
)


subdir('po')
subdir('data')

meson.add_install_script('meson/post_install.py')
