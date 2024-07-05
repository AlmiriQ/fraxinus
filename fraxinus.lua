local apply_defaults = require"default"

function execute(...)
	local f = io.popen(...);
	local result = f:read"*a";
	f:close();
	return result;
end

function overwrite_file(filename, data)
	local f, contents;
	f = io.open(filename);
	if f then
		contents = f:read"*a";
		f:close();
	end
	if contents ~= data then
		f = io.open(filename, "w");
		if f then
			f:write(data);
			f:close();
		end
	end
end

function ensure_packages(packages)
	for _, package in ipairs(packages) do
		if not os.execute([[ pacman -Qs ^]] .. package .. [[$ > /dev/null ]]) then
			os.execute("yes '' | pacman -S " .. package)
		end
	end
end

function hostname(name)
	if execute[[hostnamectl hostname | xargs]]:match("^%s*(.-)%s*$") ~= name then
		os.execute("hostnamectl hostname " .. name)
	end
end

function network(conf)
	local function network_interface(interface, ip)
		os.execute("ip link set " .. interface .. " up")	
		if ip then
			os.execute("ip address add " .. ip .. " dev " .. interface)
		end
	end

	for interface, data in pairs(conf) do
		if interface == "gateway" then
		elseif interface == "nameservers" then
		else
			network_interface(interface, data.ip);
		end
	end
	if conf.gateway then
		local gateway = conf.gateway;
		if gateway then
			os.execute("ip route add default via " .. gateway)
		end
	end
	if conf.nameservers then
		local nameservers = conf.nameservers;
		local etc_resolv = "";
		for _, nameserver in ipairs(nameservers) do
			etc_resolv = etc_resolv .. "nameserver " .. nameserver .. '\n';
		end
		overwrite_file("/etc/resolv.conf", etc_resolv);
	end
end

function openssh(conf)
	do -- install openssh if not installed
		if not os.execute [[ pacman -Qs openssh > /dev/null ]] then
			os.execute [[yes '' | pacman -S openssh]]
		end
	end -- now openssh is installed
	-- writin config
	local config = "Include /etc/ssh/sshd_config.d/*.conf\n\n";
	do -- groups
		config = config .. "AllowGroups ";
		for _, group in ipairs(conf.groups) do
			config = config .. group;
		end
		config = config .. '\n';
	end
	overwrite_file("/etc/ssh/sshd_config", config);
	
	if execute [[systemctl is-enabled sddm]] ~= "enabled" then
		os.execute [[systemctl enable --now sshd]]
	else
		os.execute [[systemctl restart sshd]]
	end
end

function users(conf)
	for user, data in pairs(conf) do
		if tonumber(execute("grep -c '" .. user .. "' /etc/passwd")) == 0 then
			local home = data.home;
			if data.simple then
				if not home then home = "/home/" .. user; end
				os.execute("mkdir " .. home);
				os.execute("useradd -d " .. home .. " " .. user);
				os.execute("chown " .. user .. ":" .. user .. " " .. home)
			else
				os.execute("useradd " .. user);
			end
			if data.groups then
				for _, group in ipairs(data.groups) do
					os.execute("groupadd " .. group);
					os.execute("usermod -aG " .. group .. " " .. user);
				end
			end
		end
		if data.fraxinus then
			print(user)
		end
	end
end

function pacman(conf)
	local etc_pacman_conf = "# /etc/pacman.conf\n\n";
	do -- options
		local options = conf.options;
		etc_pacman_conf = etc_pacman_conf .. "[options]\n"
		for key, value in pairs(options) do
			if value == true then
				etc_pacman_conf = etc_pacman_conf .. key .. "\n"
			else
				etc_pacman_conf = etc_pacman_conf .. key .. " = " .. value .. "\n"
			end
		end
		etc_pacman_conf = etc_pacman_conf .. "\n"
	end
	do -- repositories
		local repositories = conf.repositories;
		for repository, data in pairs(repositories) do
			etc_pacman_conf = etc_pacman_conf .. "["  .. repository .. "]\n"
			for option, value in pairs(data) do
				if value == true then
					etc_pacman_conf = etc_pacman_conf .. option .. "\n"
				else
					etc_pacman_conf = etc_pacman_conf .. option .. " = " .. value .. "\n"
				end
			end
			etc_pacman_conf = etc_pacman_conf .. "\n"
		end
	end
	overwrite_file("/etc/pacman.conf", etc_pacman_conf);
end

function packages(conf)
	os.execute [[yes '' | pacman -Sy]]
	os.execute [[yes '' | pacman -Su]]
	for package in conf:gmatch("([^%s]+)") do
		if not os.execute([[ pacman -Qs ^]] .. package .. [[$ > /dev/null ]]) then
			os.execute("yes '' | pacman -S " .. package)
		end
	end
end

function sddm(conf)
	if conf.enable then
		if execute [[systemctl is-enabled sddm]] ~= "enabled" then
			os.execute [[systemctl enable --now sddm]]
		end
	end
end

function sudo(conf)
	ensure_packages{ "sudo" };	
	local etc_sudoers = "";
	for key, value in pairs(conf) do
		etc_sudoers = etc_sudoers .. key .. " " .. value .. "\n\n";
	end
	etc_sudoers = etc_sudoers .. "@includedir /etc/sudoers.d";
	overwrite_file("/etc/sudoers", etc_sudoers)
end

function aur(conf)
	if conf.paru and conf.paru.enable then
		if execute[[whereis paru]]:match("^%s*(.-)%s*$") == "paru:" then
			ensure_packages{ "fakeroot", "make", "devtools", "git", "debugedit" };
			os.execute [[useradd -m -G maria paru_isntaller]]
			local f = io.open("/home/paru_isntaller/install.sh", "w")
			f:write([[echo "Installing paru"
cd
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
yes '' | makepkg -si]])
			f:close()
			os.execute [[sudo -u paru_isntaller bash /home/paru_isntaller/install.sh]]
			os.execute [[rm -rf /home/paru_installer]]
			os.execute [[userdel paru_isntaller]]			
			os.execute [[useradd -m -G maria paru]]
		end
	end
end

function main()
	local configuration = apply_defaults(require"conf");

	for config, data in pairs(configuration) do
		_G[config](data);
	end
end

main();
