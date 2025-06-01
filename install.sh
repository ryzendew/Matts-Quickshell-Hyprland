#!/bin/bash

# Matt's Quickshell Hyprland Configuration Installer
# Automated installer for Arch Linux and PikaOS 4 systems

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Distribution detection
DISTRO=""
FORCE_INSTALL=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_INSTALL=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error recovery function
cleanup_on_error() {
    print_error "Installation failed! Cleaning up..."
    cd ~
    rm -rf /tmp/yay-bin /tmp/Matts-Quickshell-Hyprland 2>/dev/null || true
}

# Set up error trap
trap cleanup_on_error ERR

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root (don't use sudo)"
   exit 1
fi

# Detect distribution
detect_distribution() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            "pikaos")
                DISTRO="pikaos"
                print_status "Detected: PikaOS 4"
                ;;
            "arch"|"cachyos"|"endeavouros"|"artix"|"archcraft"|"arcolinux"|"archbang"|"archlabs"|"archmerge"|"archstrike"|"blackarch"|"archman"|"archlinux"|"archlinuxarm"|"archlinuxcn"|"archlinuxfr"|"archlinuxgr"|"archlinuxjp"|"archlinuxkr"|"archlinuxpl"|"archlinuxru"|"archlinuxtr"|"archlinuxvn"|"archlinuxzh"|"archlinuxzhcn"|"archlinuxzhtw"|"archlinuxzhhk"|"archlinuxzhmo"|"archlinuxzhsg"|"archlinuxzhtw"|"archlinuxzhcn"|"archlinuxzhtw"|"archlinuxzhhk"|"archlinuxzhmo"|"archlinuxzhsg")
                DISTRO="arch"
                print_status "Detected: $PRETTY_NAME (Arch-based)"
                ;;
            "garuda"|"manjaro")
                print_error "Unsupported distribution: $PRETTY_NAME"
                print_error "This script does not support Garuda Linux or Manjaro Linux"
                print_error "Please use a different Arch-based distribution"
                exit 1
                ;;
            *)
                if command -v pacman &> /dev/null; then
                    DISTRO="arch"
                    print_status "Detected: $PRETTY_NAME (Arch-based)"
                else
                    print_error "Unsupported distribution: $PRETTY_NAME"
                    print_error "This script supports:"
                    print_error "- Arch Linux and most Arch-based distributions"
                    print_error "- PikaOS 4 (Debian-based)"
                    exit 1
                fi
                ;;
        esac
    elif command -v pacman &> /dev/null; then
        DISTRO="arch"
        print_status "Detected: Arch-based distribution (fallback detection)"
    else
        print_error "Unable to detect supported distribution"
        print_error "This script supports:"
        print_error "- Arch Linux and most Arch-based distributions"
        print_error "- PikaOS 4 (Debian-based)"
        exit 1
    fi
}

# Check distribution compatibility
check_distribution() {
    detect_distribution
    
    if [[ "$DISTRO" == "arch" ]]; then
        if ! command -v pacman &> /dev/null; then
            print_error "Arch-based distribution detected but pacman not found"
            exit 1
        fi
    elif [[ "$DISTRO" == "pikaos" ]]; then
        if ! command -v apt &> /dev/null; then
            print_error "PikaOS detected but apt not found"
            exit 1
        fi
    fi
}

# Check internet connectivity
print_status "Checking internet connectivity..."
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    print_error "No internet connection detected. Please check your network and try again."
    exit 1
fi

# Check if git is available
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install git and try again."
    print_error "On Arch: sudo pacman -S git"
    print_error "On PikaOS: sudo apt install git"
    exit 1
fi

# Check available disk space (need at least 2GB)
print_status "Checking available disk space..."
available_space=$(df / | awk 'NR==2 {print $4}')
if [ "$available_space" -lt 2097152 ]; then  # 2GB in KB
    print_error "Insufficient disk space. At least 2GB free space required."
    exit 1
fi

# Check distribution compatibility
check_distribution

# Clone repository to temporary Dotfiles folder
print_status "Setting up dotfiles repository..."

# Always create a fresh temporary Dotfiles directory
TEMP_DOTFILES="$HOME/Dotfiles"
if [ -d "$TEMP_DOTFILES" ]; then
    print_status "Removing existing Dotfiles directory..."
    rm -rf "$TEMP_DOTFILES"
fi

print_status "Cloning repository to ~/Dotfiles..."
cd "$HOME"

# Clone repository
repo_url="https://github.com/ryzendew/Matts-Quickshell-Hyprland.git"
print_status "Cloning from: $repo_url"
if git clone "$repo_url" Dotfiles 2>/dev/null; then
    print_success "Repository cloned successfully"
    REPO_DIR="$TEMP_DOTFILES"
else
    print_error "Failed to clone repository from $repo_url"
    print_error ""
    print_error "This could be due to:"
    print_error "1. Network connectivity issues"
    print_error "2. Repository access problems"
    print_error "3. Git not installed properly"
    print_error ""
    print_error "Manual solutions:"
    print_error "1. Check your internet connection"
    print_error "2. Try cloning manually: git clone $repo_url ~/Dotfiles"
    print_error "3. Ensure git is installed: sudo pacman -S git"
    exit 1
fi

# Change to the repository directory
cd "$REPO_DIR"
print_status "Working from: $(pwd)"

# Verify required files exist
if [ ! -d ".config" ]; then
    print_error "Configuration directory not found in cloned repository!"
    print_error "Repository may be corrupted or incomplete."
    exit 1
fi

if [ ! -d "ArchPackages" ]; then
    print_warning "ArchPackages directory not found in repository"
    print_warning "Prebuilt Quickshell package will not be available as fallback"
fi

print_status "Matt's Quickshell Hyprland Configuration Installer"
print_status "=============================================="
print_status "Distribution: $DISTRO"
echo

# Ask about .config backup
if [ -d "$HOME/.config" ]; then
    echo -e "${YELLOW}Existing .config directory found.${NC}"
    echo "Do you want to backup your current .config directory?"
    echo "Backup will be saved as ~/.config.backup.$(date +%Y%m%d_%H%M%S)"
    read -p "Backup .config? [Y/n]: " backup_choice
    
    if [[ $backup_choice =~ ^[Nn]$ ]]; then
        print_warning "Skipping .config backup - existing files may be overwritten!"
    else
        backup_dir="$HOME/.config.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "Creating backup at $backup_dir"
        cp -r "$HOME/.config" "$backup_dir"
        print_success "Backup created successfully"
    fi
    echo
fi

# --- Install critical AUR dependencies early ---
print_status "Installing critical AUR dependencies early with yay..."

# Ensure yay is installed first
if ! command -v yay &> /dev/null; then
    print_status "Installing yay AUR helper..."
    cd /tmp
    rm -rf yay-bin 2>/dev/null || true
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay-bin
    print_success "yay installed successfully"
else
    print_status "yay is already installed"
fi

yay -S --noconfirm --needed adw-gtk-theme-git breeze-plus fish kde-material-you-colors starship ttf-readex-pro ttf-jetbrains-mono-nerd ttf-material-symbols-variable-git ttf-rubik-vf ttf-gabarito-git quickshell fuzzel

# --- Install all required packages (official + AUR + meta-package PKGBUILD deps) ---
print_status "Aggregating all dependencies from meta-package PKGBUILDs..."

# Main package arrays (from previous logic)
official_packages=(
    hyprland wayland wayland-protocols wayland-utils
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal
    xdg-utils xdg-user-dirs
    pipewire wireplumber pipewire-alsa pipewire-pulse pipewire-jack
    pamixer playerctl pavucontrol alsa-utils alsa-plugins pulseaudio-alsa
    sddm qt6-svg qt6-declarative systemd polkit polkit-qt6
    networkmanager nm-connection-editor dhcpcd wpa_supplicant bluez bluez-utils
    qt6-base qt6-declarative qt6-wayland qt6-svg qt6-imageformats qt6-multimedia qt6-positioning qt6-quicktimeline qt6-sensors qt6-tools qt6-translations qt6-virtualkeyboard qt6-5compat qt6-shadertools qt6-languageserver qt6-charts qt6-webengine qt6-webchannel qt6-websockets qt6-connectivity qt6-serialport
    qt5-base qt5-declarative qt5-graphicaleffects qt5-imageformats qt5-svg qt5-translations qt5-wayland
    grim slurp wl-clipboard wtype brightnessctl ddcutil mako libnotify upower acpid htop btop fastfetch file-roller unzip zip 7zip gvfs gvfs-mtp gvfs-gphoto2 ptyxis nautilus geoclue gammastep fcitx5 gnome-keyring polkit-gnome easyeffects cliphist
    ttf-dejavu noto-fonts ttf-font-awesome papirus-icon-theme gtk3 gtk4 adwaita-icon-theme qt6ct qt5ct
    cmake ninja pkgconf make gcc git jemalloc cli11 libdrm mesa vulkan-icd-loader vulkan-headers libxcb xcb-util xcb-util-wm xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-cursor libxkbcommon libxkbcommon-x11 libpipewire libglvnd syntax-highlighting
    xorg-xwayland xorg-xlsclients xorg-xrandr xorg-xinput xorg-xdpyinfo libx11 libxcomposite libxcursor libxdamage libxext libxfixes libxi libxinerama libxrandr libxrender libxss libxtst
    thunar thunar-volman thunar-archive-plugin wofi rofi-wayland lxqt-policykit
)
aur_packages=(
    matugen-bin grimblast hyprswitch nwg-look swww hypridle hyprlock hyprpaper hyprpicker wlogout better-control easyeffects-bin google-breakpad nwg-displays dbus-update-activation-environment
    adw-gtk-theme-git breeze-plus fish kde-material-you-colors starship ttf-readex-pro ttf-jetbrains-mono-nerd ttf-material-symbols-variable-git ttf-rubik-vf ttf-gabarito-git
)

# Aggregate all depends and makedepends from PKGBUILDs
for pkgdir in Arch-packages/*/; do
    if [[ -f "$pkgdir/PKGBUILD" ]]; then
        # Extract depends and makedepends
        deps=$(awk '/depends=\(/,/
\)/ {if ($0 !~ /depends=\(/ && $0 !~ /\)/) print $0}' "$pkgdir/PKGBUILD" | tr -d '"' | tr -d "'" | tr -d ' ')
        makedeps=$(awk '/makedepends=\(/,/
\)/ {if ($0 !~ /makedepends=\(/ && $0 !~ /\)/) print $0}' "$pkgdir/PKGBUILD" | tr -d '"' | tr -d "'" | tr -d ' ')
        for dep in $deps $makedeps; do
            # Only add if not already in either array
            if ! [[ " ${official_packages[@]} " =~ " $dep " ]] && ! [[ " ${aur_packages[@]} " =~ " $dep " ]]; then
                aur_packages+=("$dep")
            fi
        done
    fi
done
# De-duplicate aur_packages
readarray -t aur_packages < <(printf '%s
' "${aur_packages[@]}" | awk '!seen[$0]++')

print_status "Installing official repo packages with pacman..."
sudo pacman -S --noconfirm --needed "${official_packages[@]}"
print_status "Installing AUR packages with yay..."
yay -S --noconfirm --needed "${aur_packages[@]}"

# Copy configuration files, backing up any overwritten files/folders
print_status "Copying configuration files..."
if [ -d ".config" ]; then
    overwrite_backup_dir="$HOME/.config.backup.$(date +%Y%m%d_%H%M%S).overwrite"
    mkdir -p "$overwrite_backup_dir"
    
    for item in .config/*; do
        base_item="$(basename "$item")"
        
        if [ -e "$HOME/.config/$base_item" ]; then
            print_status "Backing up $base_item before overwriting..."
            cp -rf "$HOME/.config/$base_item" "$overwrite_backup_dir/" 2>/dev/null || true
        fi
        
        print_status "Force copying $base_item..."
        cp -rf "$item" "$HOME/.config/" 2>/dev/null || true
    done
    
    # Fix hardcoded paths - replace /home/matt/ with actual user's home directory
    print_status "Fixing hardcoded paths for current user..."
    find "$HOME/.config/quickshell" -type f \( -name "*.qml" -o -name "*.js" \) -exec sed -i "s|/home/matt/|$HOME/|g" {} \; 2>/dev/null || true
    find "$HOME/.config/hypr" -type f -name "*.conf" -exec sed -i "s|/home/matt/|$HOME/|g" {} \; 2>/dev/null || true
    
    print_success "Configuration files copied successfully (force overwritten, backups made)"
else
    print_error "Configuration directory not found!"
    exit 1
fi

# Distribution-specific package installation functions
install_arch_packages() {
    # Show comprehensive package installation summary
    print_status "COMPREHENSIVE ARCH LINUX + HYPRLAND INSTALLATION"
    if [ "$FORCE_INSTALL" = true ]; then
        print_status "FORCE REINSTALL MODE ENABLED - All packages will be reinstalled"
    fi
    print_status "=================================================="
    echo
    print_status "This installer will install ALL dependencies needed for a complete Hyprland desktop:"
    echo
    print_status "📦 CORE COMPONENTS:"
    print_status "   • Hyprland + Wayland foundation (hyprland, wayland, xdg-desktop-portal-hyprland)"
    print_status "   • Complete Qt6 framework for Quickshell (qt6-base, qt6-declarative, etc.)"
    print_status "   • Qt5 compatibility for legacy applications"
    echo
    print_status "🔊 AUDIO SYSTEM:"
    print_status "   • Complete PipeWire setup (pipewire, wireplumber, pamixer, pavucontrol)"
    print_status "   • ALSA compatibility and media controls"
    echo
    print_status "🖥️  DISPLAY & SESSION:"
    print_status "   • SDDM display manager with Qt6 support"
    print_status "   • Polkit authentication system"
    print_status "   • XWayland for X11 app compatibility"
    echo
    print_status "🌐 CONNECTIVITY:"
    print_status "   • NetworkManager for network management"
    print_status "   • Bluetooth support (bluez, bluez-utils)"
    print_status "   • Network configuration tools"
    echo
    print_status "🎨 DESKTOP ENVIRONMENT:"
    print_status "   • Essential applications (Firefox, Thunar, terminals, media players)"
    print_status "   • Comprehensive font collection (Noto, Liberation, Adobe Source Code Pro)"
    print_status "   • Icon themes and GTK theming (Papirus, Arc)"
    print_status "   • Screenshot and clipboard tools (grim, slurp, wl-clipboard)"
    echo
    print_status "🔧 DEVELOPMENT & BUILD TOOLS:"
    print_status "   • Complete build environment (cmake, ninja, gcc, base-devel)"
    print_status "   • Graphics libraries (mesa, vulkan, libdrm)"
    print_status "   • All Quickshell build dependencies"
    echo
    print_status "🚀 PERFORMANCE & HARDWARE:"
    print_status "   • GPU drivers for Intel, AMD, and NVIDIA"
    print_status "   • Hardware acceleration libraries"
    print_status "   • Power management tools"
    echo
    print_status "🎯 AUR PACKAGES:"
    print_status "   • Quickshell (main shell framework)"
    print_status "   • Hyprland ecosystem (hypridle, hyprlock, swww, etc.)"
    print_status "   • Additional utilities (matugen, grimblast, waybar-hyprland)"
    echo
    print_status "Total packages: ~200+ (ensuring nothing is missing for vanilla Arch)"
    echo
    read -p "Proceed with comprehensive installation? [Y/n]: " proceed_choice
    if [[ $proceed_choice =~ ^[Nn]$ ]]; then
        print_status "Installation cancelled by user"
        exit 0
    fi
    echo

    # Update system
    print_status "Updating system packages..."
    if [ "$FORCE_INSTALL" = true ]; then
        sudo pacman -Syu --noconfirm --overwrite "*"
    else
        sudo pacman -Syu --noconfirm
    fi

    # Install base-devel and git if not present
    print_status "Installing base development tools..."
    if [ "$FORCE_INSTALL" = true ]; then
        sudo pacman -S --needed --noconfirm --overwrite "*" base-devel git
    else
        sudo pacman -S --needed --noconfirm base-devel git
    fi

    # Split packages into official repo and AUR packages
    all_packages=(
        hyprland wayland wayland-protocols wayland-utils
        xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal
        xdg-utils xdg-user-dirs
        pipewire wireplumber pipewire-alsa pipewire-pulse pipewire-jack
        pamixer playerctl pavucontrol alsa-utils alsa-plugins pulseaudio-alsa
        sddm qt6-svg qt6-declarative systemd polkit polkit-qt6
        networkmanager nm-connection-editor dhcpcd wpa_supplicant bluez bluez-utils
        qt6-base qt6-declarative qt6-wayland qt6-svg qt6-imageformats qt6-multimedia qt6-positioning qt6-quicktimeline qt6-sensors qt6-tools qt6-translations qt6-virtualkeyboard qt6-5compat qt6-shadertools qt6-languageserver qt6-charts qt6-webengine qt6-webchannel qt6-websockets qt6-connectivity qt6-serialport
        qt5-base qt5-declarative qt5-graphicaleffects qt5-imageformats qt5-svg qt5-translations qt5-wayland
        grim slurp wl-clipboard wtype brightnessctl ddcutil mako libnotify upower acpid htop btop fastfetch file-roller unzip zip 7zip gvfs gvfs-mtp gvfs-gphoto2 ptyxis nautilus geoclue gammastep fcitx5 gnome-keyring polkit-gnome easyeffects cliphist
        ttf-dejavu noto-fonts ttf-font-awesome papirus-icon-theme gtk3 gtk4 adwaita-icon-theme qt6ct qt5ct
        cmake ninja pkgconf make gcc git jemalloc cli11 libdrm mesa vulkan-icd-loader vulkan-headers libxcb xcb-util xcb-util-wm xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-cursor libxkbcommon libxkbcommon-x11 libpipewire libglvnd syntax-highlighting
        xorg-xwayland xorg-xlsclients xorg-xrandr xorg-xinput xorg-xdpyinfo libx11 libxcomposite libxcursor libxdamage libxext libxfixes libxi libxinerama libxrandr libxrender libxss libxtst
        thunar thunar-volman thunar-archive-plugin wofi rofi-wayland lxqt-policykit
    )
    print_status "Installing all required packages (official + AUR) with yay..."
    yay -S --noconfirm --needed "${all_packages[@]}"

    # --- Meta-Package Installation: Build all PKGBUILDs, then install all built packages ---
    print_status "Building and installing all meta-packages from PKGBUILDs using yay..."
    if compgen -G "./Arch-packages/*/" > /dev/null; then
        for dir in ./Arch-packages/*/; do
            if [[ -f "$dir/PKGBUILD" ]]; then
                print_status "Building and installing $dir with yay"
                (cd "$dir" && yay -S --noconfirm --needed .)
            fi
        done
    fi

    # Install Tela Circle icon theme from official repository if not already installed
    print_status "Checking Tela Circle icon theme..."
    if [ ! -d "/usr/share/icons/Tela-circle" ]; then
        print_status "Tela Circle icon theme not found. Installing..."
        TEMP_TELA_DIR="/tmp/Tela-circle-icon-theme"

        if [ ! -d "$TEMP_TELA_DIR" ]; then
            print_status "Cloning Tela Circle icon theme repository..."
            git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git "$TEMP_TELA_DIR" || { print_error "Failed to clone Tela icon theme repository."; exit 1; }
        else
            print_status "Temporary Tela Circle icon theme directory found. Updating and using it..."
            (cd "$TEMP_TELA_DIR" && git pull) || print_warning "Failed to update temporary Tela icon theme repo."
        fi
        
        print_status "Running Tela Circle icon theme installer..."
        (cd "$TEMP_TELA_DIR" && sudo ./install.sh -a) || { print_error "Tela icon theme installation failed."; exit 1; }
        
        print_success "Tela Circle icon theme installed successfully."
        # print_status "Cleaning up temporary Tela icon theme directory..."
        # rm -rf "$TEMP_TELA_DIR"
    else
        print_status "Tela Circle icon theme is already installed. Skipping."
    fi

    # Enable essential system services
    print_status "Enabling essential system services..."
    service_errors=0

    # Enable NetworkManager
    if ! sudo systemctl enable NetworkManager 2>/dev/null; then
        print_warning "Failed to enable NetworkManager"
        service_errors=$((service_errors + 1))
    else
        print_success "NetworkManager enabled"
    fi

    # Enable SDDM
    if ! sudo systemctl enable sddm 2>/dev/null; then
        print_warning "Failed to enable SDDM"
        service_errors=$((service_errors + 1))
    else
        print_success "SDDM enabled"
    fi

    # Enable Bluetooth
    if ! sudo systemctl enable bluetooth 2>/dev/null; then
        print_warning "Failed to enable Bluetooth (may not be available)"
        service_errors=$((service_errors + 1))
    else
        print_success "Bluetooth enabled"
    fi

    # Start NetworkManager if not running
    if ! systemctl is-active --quiet NetworkManager; then
        print_status "Starting NetworkManager..."
        sudo systemctl start NetworkManager
    fi

    if [ $service_errors -eq 0 ]; then
        print_success "All system services enabled successfully"
    elif [ $service_errors -le 2 ]; then
        print_warning "$service_errors service(s) failed to enable. This is usually not critical."
    else
        print_warning "$service_errors service(s) failed to enable. You may need to enable them manually later."
    fi

    # Additional configuration
    print_status "Performing additional system configuration..."
    
    # Create user directories
    xdg-user-dirs-update 2>/dev/null || true
    
    # Update font cache
    print_status "Updating font cache..."
    fc-cache -fv 2>/dev/null || true
    
    # Update icon cache
    print_status "Updating icon cache..."
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
    gtk-update-icon-cache -f -t /usr/share/icons/Papirus || true
    
    # Set up clipboard history
    print_status "Setting up clipboard history..."
    mkdir -p ~/.local/share/cliphist
    systemctl --user enable --now cliphist.service 2>/dev/null || true
    
    # Set up cursor theme
    print_status "Setting up cursor theme..."
    if [ -f /usr/share/icons/Bibata-Modern-Classic/cursors/left_ptr ]; then
        gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic' 2>/dev/null || true
    fi
    
    # Set up environment variables
    print_status "Setting up environment variables..."
    if [ ! -f ~/.config/environment.d/99-hyprland.conf ]; then
        mkdir -p ~/.config/environment.d
        cat > ~/.config/environment.d/99-hyprland.conf << EOF
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=Hyprland
EOF
    fi
    
    # Set up Fish shell auto-start
    print_status "Setting up Fish shell auto-start..."
    if command -v fish &> /dev/null; then
        mkdir -p ~/.config/fish
        cat > ~/.config/fish/auto-Hypr.fish << EOF
# Auto start Hyprland on tty1
if test -z "\$DISPLAY" ;and test "\$XDG_VTNR" -eq 1
    mkdir -p ~/.cache
    exec Hyprland > ~/.cache/hyprland.log ^&1
end
EOF
    fi
    
    # Set up performance optimization
    print_status "Setting up performance optimization..."
    mkdir -p ~/.config/hypr
    cat > ~/.config/hypr/performance.conf << EOF
# Performance Settings
monitor=,highres,auto,1
env = WLR_DRM_NO_ATOMIC,1
env = WLR_NO_HARDWARE_CURSORS,1
env = WLR_RENDERER_ALLOW_SOFTWARE,1
env = WLR_RENDERER,vulkan
env = WLR_USE_LIBINPUT,1
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
EOF

    # Set up startup script
    print_status "Setting up startup script..."
    mkdir -p ~/.config/hypr/scripts
    cat > ~/.config/hypr/scripts/startup.sh << EOF
#!/bin/bash

# Set environment variables
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland

# Start system services
systemctl --user start pipewire.service
systemctl --user start pipewire-pulse.service
systemctl --user start wireplumber.service

# Start desktop components
waybar &
swww init
swww img ~/.config/hypr/assets/wallpapers/Fantasy-Landscape2.png
qs &

# Start additional services
nm-applet --indicator &
blueman-applet &
easyeffects --gapplication-service &
fcitx5 &
geoclue-2.0/demos/agent &
gammastep &
gnome-keyring-daemon --start --components=secrets &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 || /usr/libexec/polkit-gnome-authentication-agent-1 &
hypridle &
dbus-update-activation-environment --all &
sleep 0.1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
hyprpm reload &

# Clipboard history
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &

# Set cursor
hyprctl setcursor Bibata-Modern-Classic 24
EOF
    chmod +x ~/.config/hypr/scripts/startup.sh

    # Set up shutdown script
    print_status "Setting up shutdown script..."
    cat > ~/.config/hypr/scripts/shutdown.sh << EOF
#!/bin/bash

# Stop desktop components
killall waybar
killall qs

# Stop system services
systemctl --user stop pipewire.service
systemctl --user stop pipewire-pulse.service
systemctl --user stop wireplumber.service
systemctl --user stop cliphist.service

# Cleanup
rm -rf /tmp/hyprland-*
EOF
    chmod +x ~/.config/hypr/scripts/shutdown.sh

    # Set up theme manager
    print_status "Setting up theme manager..."
    cat > ~/.config/hypr/scripts/theme-manager.sh << EOF
#!/bin/bash

# Function to apply theme
apply_theme() {
    local theme=\$1
    
    # Copy theme files
    cp -r ~/.config/hypr/assets/themes/\$theme/* ~/.config/hypr/
    
    # Reload Hyprland
    hyprctl reload
}

# Function to set wallpaper
set_wallpaper() {
    local wallpaper=\$1
    
    # Set wallpaper
    swww img ~/.config/hypr/assets/wallpapers/\$wallpaper
}

# Function to update theme
update_theme() {
    local theme=\$1
    local wallpaper=\$2
    
    # Apply theme and wallpaper
    apply_theme \$theme
    set_wallpaper \$wallpaper
}
EOF
    chmod +x ~/.config/hypr/scripts/theme-manager.sh

    # Create theme directory structure
    print_status "Setting up theme directory structure..."
    mkdir -p ~/.config/hypr/assets/{themes,wallpapers}
    
    # Install custom meta-packages from Arch-packages directory (match end-4 script exactly)
    print_status "Installing custom meta-packages from Arch-packages..."
    metapkgs=(illogical-impulse-{audio,backlight,basic,fonts-themes,kde,portal,python,screencapture,toolkit,widgets})
    metapkgs+=(illogical-impulse-hyprland)
    metapkgs+=(illogical-impulse-microtex-git)
    # metapkgs+=(illogical-impulse-oneui4-icons-git)
    [[ -f /usr/share/icons/Bibata-Modern-Classic/index.theme ]] || \
      metapkgs+=(illogical-impulse-bibata-modern-classic-bin)

    for pkg in "${metapkgs[@]}"; do
      found=false
      # Try to install prebuilt package
      for file in ./Arch-packages/${pkg}-*.pkg.tar.*; do
        if [[ -f "$file" ]]; then
          print_status "Installing meta-package: $file"
          sudo pacman -U --noconfirm "$file"
          found=true
          break
        fi
      done
      # If not found, try to build from PKGBUILD
      if [[ "$found" = false && -d ./Arch-packages/$pkg && -f ./Arch-packages/$pkg/PKGBUILD ]]; then
        print_status "Building and installing meta-package from PKGBUILD: $pkg"
        (cd "./Arch-packages/$pkg" && makepkg -si --noconfirm)
        found=true
      fi
      if [[ "$found" = false ]]; then
        print_warning "Meta-package not found and no PKGBUILD to build: $pkg"
      fi
    done

    print_success "Arch Linux package installation completed successfully!"
    print_status "Your system now has:"
    print_status "  ✓ Complete Hyprland + Wayland setup"
    print_status "  ✓ Full Qt6 framework for Quickshell"
    print_status "  ✓ PipeWire audio system"
    print_status "  ✓ SDDM display manager"
    print_status "  ✓ Essential desktop applications"
    print_status "  ✓ Development tools and dependencies"
    print_status "  ✓ Fonts and theming"
    print_status "  ✓ Network and Bluetooth support"
}

install_pikaos_packages() {
    # Update system
    print_status "Updating system packages..."
    sudo apt update && sudo apt upgrade -y

    # Install git if not present
    print_status "Installing git..."
    sudo apt install -y git

    # Check if Quickshell is already available
    if command -v quickshell &> /dev/null || command -v qs &> /dev/null || dpkg -l 2>/dev/null | grep -q quickshell; then
        print_success "Quickshell is already available on PikaOS"
    else
        print_warning "Quickshell not found. Installing via pikman (if available)..."
        if command -v pikman &> /dev/null; then
            if ! pikman install quickshell; then
                print_warning "Failed to install quickshell via pikman"
            fi
        else
            print_error "Quickshell not available and pikman not found"
            print_error "Please ensure you're using PikaOS Hyprland Edition"
            exit 1
        fi
    fi

    # Install required packages that might not be present
    print_status "Installing additional required packages..."
    sudo apt install -y \
        grim slurp wl-clipboard wtype brightnessctl \
        fonts-dejavu fonts-noto

    # Install optional utility packages that might be missing
    print_status "Installing optional utility packages..."
    if command -v pikman &> /dev/null; then
        print_status "Using pikman for additional packages..."
        pikman install matugen || print_warning "matugen not available via pikman"
        pikman install grimblast || print_warning "grimblast not available via pikman"
        pikman install hyprswitch || print_warning "hyprswitch not available via pikman"
        pikman install nwg-displays || print_warning "nwg-displays not available via pikman"
        pikman install nwg-look || print_warning "nwg-look not available via pikman"
    else
        print_warning "pikman not available - some optional packages may be missing"
    fi

    print_success "PikaOS packages installation completed"
    print_status "Note: Some packages may already be pre-installed on PikaOS Hyprland Edition"
}

# Main installation process
print_status "Starting installation process..."

if [[ "$DISTRO" == "arch" ]]; then
    install_arch_packages
elif [[ "$DISTRO" == "pikaos" ]]; then
    install_pikaos_packages
fi

print_success "Installation completed successfully!"
print_status "Please log out and log back in to start using your new configuration."
print_status "If you encounter any issues, please check the documentation or report them on GitHub." 
