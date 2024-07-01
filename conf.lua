local path = require"path"

return {
	network = require"network",
	openssh = {
		groups = {
			"remote"
		}
	},
	users = {
		almiriqi = {
			simple = true,
			fraxinus = true,
			groups = { "almiriqi", "wheel" }
		},
		maria = {
			simple = true,
			groups = { "maria", "wheel", "remote" }
		}
	},
	pacman = {
		options = {
			ParallelDownloads = 20
		},
		repositories = {
			core     = { Include = path [[/etc/pacman.d/mirrorlist]] },
			extra    = { Include = path [[/etc/pacman.d/mirrorlist]] },
			multilib = { Include = path [[/etc/pacman.d/mirrorlist]] }
		}
	},
	packages = require"packages",
	sddm = { enable = true }
};
