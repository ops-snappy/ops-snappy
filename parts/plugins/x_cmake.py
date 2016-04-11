import snapcraft.plugins.cmake
import snapcraft


class XCmakePlugin(snapcraft.plugins.cmake.CMakePlugin):
    @classmethod
    def schema(cls):
        schema = super().schema()
        schema['properties']['precmd'] = {
            'type': 'array',
            'minitems': 1,
            'items': {
                'type': 'string',
            },
            'default': [],
        }
        schema['properties']['postcmd'] = {
            'type': 'array',
            'minitems': 1,
            'items': {
                'type': 'string',
            },
            'default': [],
        }
        return schema

    def build(self):
        baseplugin = snapcraft.BasePlugin
        baseplugin.build(self)

        if self.options.precmd:
            self.run(self.options.precmd)

        save = baseplugin.build
        baseplugin.build = lambda self: None
        super().build()
        baseplugin.build = save

        if self.options.postcmd:
            self.run(self.options.postcmd)
