project('miro-app', 'vala', 'c')

dependencies = [
    dependency('glib-2.0'),
    dependency('gio-2.0'),
    dependency('gtk+-3.0'),
    dependency('granite'),
    dependency('webkit2gtk-4.1'),
    dependency('libhandy-1'),
]

executable('miro-native-vala',
    'src/MiroApp.vala',
    dependencies: dependencies,
    install: true
)
