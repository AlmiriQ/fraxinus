local path = require"path"

return {
	hostname = "aqore",
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
	sddm = { enable = true },
	aur = {
		paru = { enable = true }
	},
	sudo = {
		root = "ALL=(ALL:ALL) ALL",
		["%wheel"] = "ALL=(ALL:ALL) ALL",
		["%maria"] = "ALL=(ALL:ALL) NOPASSWD: ALL"
	}
};
