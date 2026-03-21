project('figma-app', 'vala', 'c')

dependencies = [
    dependency('glib-2.0'),
    dependency('gio-2.0'),
    dependency('gtk+-3.0'),
    dependency('granite'),
    dependency('webkit2gtk-4.1'),
]

executable('figma-native-vala',
    'src/FigmaApp.vala',
    dependencies: dependencies,
    install: true
)
