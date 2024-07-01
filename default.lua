local path = require"path"

local default = {
	pacman = {
		options = {
			HoldPkg           = "pacman glibc",
			Architecture      = "auto",
			CheckSpace        = true,
			LocalFileSigLevel = "Optional",
			SigLevel          = "Required DatabaseOptional"
		},
		repositories = {
			core     = { Include = path [[/etc/pacman.d/mirrorlist]] },
			extra    = { Include = path [[/etc/pacman.d/mirrorlist]] },
		}
	},
};

function apply(conf, key, data)
	if not conf[key] then
		conf[key] = data
	end
end

return function(configuration)
	do
		local pacman = configuration.pacman;
		local options = pacman.options;
		local repositories = pacman.repositories;
		for key, value in pairs(default.pacman.options) do
			apply(options, key, value);
		end
		for key, value in pairs(default.pacman.repositories) do
			apply(repositories, key, value);
		end
	end
	return configuration;
end
