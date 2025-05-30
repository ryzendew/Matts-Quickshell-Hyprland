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
    sudo pacman -Syu --noconfirm

    # Install base-devel and git if not present
    print_status "Installing base development tools..."
    sudo pacman -S --needed --noconfirm base-devel git

    # Install yay-bin if not present
    if ! command -v yay &> /dev/null; then
        print_status "Installing yay AUR helper..."
        cd /tmp
        
        # Clean up any existing yay-bin directory
        rm -rf yay-bin 2>/dev/null || true
        
        # Clone with retry mechanism
        retry_count=0
        while [ $retry_count -lt 3 ]; do
            if git clone https://aur.archlinux.org/yay-bin.git 2>/dev/null; then
                break
            else
                retry_count=$((retry_count + 1))
                print_warning "Git clone failed, attempt $retry_count/3"
                if [ $retry_count -lt 3 ]; then
                    sleep 2
                fi
            fi
        done
        
        if [ $retry_count -eq 3 ]; then
            print_error "Failed to clone yay-bin repository after 3 attempts"
            exit 1
        fi
        
        cd yay-bin
        
        # Build with error handling
        if ! makepkg -si --noconfirm; then
            print_error "Failed to build yay-bin. This could be due to:"
            print_error "1. Missing base-devel packages"
            print_error "2. Network issues during dependency download"
            print_error "3. Compilation errors"
            exit 1
        fi
        
        cd ~
        rm -rf /tmp/yay-bin
        print_success "yay installed successfully"
    else
        print_status "yay is already installed"
    fi

    # COMPREHENSIVE PACKAGE INSTALLATION FOR VANILLA ARCH + HYPRLAND
    print_status "Installing comprehensive package set for complete Hyprland desktop environment..."
    
    # CORE HYPRLAND AND WAYLAND FOUNDATION
    print_status "Installing core Hyprland and Wayland components..."
    if ! sudo pacman -S --needed --noconfirm \
        hyprland wayland wayland-protocols wayland-utils \
        xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal \
        xdg-utils xdg-user-dirs; then
        print_error "Failed to install core Hyprland/Wayland packages"
        exit 1
    fi

    # AUDIO SYSTEM - Complete PipeWire setup
    print_status "Installing complete audio system (PipeWire)..."
    
    # Handle JACK conflict - remove jack2 and related packages if they exist
    if pacman -Q jack2 &>/dev/null; then
        print_status "Removing conflicting JACK packages..."
        # Remove jack2 and any packages that depend on it
        sudo pacman -Rdd --noconfirm jack2 2>/dev/null || true
        # Also check for other JACK-related packages
        sudo pacman -Rdd --noconfirm jack 2>/dev/null || true
    fi
    
    # Install PipeWire core first
    if ! sudo pacman -S --needed --noconfirm \
        pipewire wireplumber; then
        print_error "Failed to install PipeWire core"
        exit 1
    fi
    
    # Install PipeWire compatibility layers
    if ! sudo pacman -S --needed --noconfirm \
        pipewire-alsa pipewire-pulse pipewire-jack; then
        print_error "Failed to install PipeWire compatibility layers"
        exit 1
    fi
    
    # Install audio utilities
    if ! sudo pacman -S --needed --noconfirm \
        pamixer playerctl pavucontrol \
        alsa-utils alsa-plugins pulseaudio-alsa; then
        print_error "Failed to install audio utilities"
        exit 1
    fi

    # DISPLAY MANAGER AND SESSION MANAGEMENT
    print_status "Installing display manager and session components..."
    if ! sudo pacman -S --needed --noconfirm \
        sddm qt6-svg qt6-declarative \
        systemd polkit polkit-qt6; then
        print_error "Failed to install display manager packages"
        exit 1
    fi

    # NETWORK MANAGEMENT
    print_status "Installing network management..."
    if ! sudo pacman -S --needed --noconfirm \
        networkmanager nm-connection-editor \
        dhcpcd wpa_supplicant \
        bluez bluez-utils; then
        print_error "Failed to install network management packages"
        exit 1
    fi

    # QT6 FRAMEWORK - Complete Qt6 installation for Quickshell
    print_status "Installing complete Qt6 framework..."
    if ! sudo pacman -S --needed --noconfirm \
        qt6-base qt6-declarative qt6-wayland qt6-svg qt6-imageformats \
        qt6-multimedia qt6-positioning qt6-quicktimeline qt6-sensors \
        qt6-tools qt6-translations qt6-virtualkeyboard qt6-5compat \
        qt6-shadertools qt6-languageserver qt6-charts qt6-webengine \
        qt6-webchannel qt6-websockets qt6-connectivity qt6-serialport; then
        print_error "Failed to install Qt6 framework packages"
        exit 1
    fi

    # QT5 COMPATIBILITY (some apps still need it)
    print_status "Installing Qt5 compatibility packages..."
    if ! sudo pacman -S --needed --noconfirm \
        qt5-base qt5-declarative qt5-graphicaleffects \
        qt5-imageformats qt5-svg qt5-translations qt5-wayland; then
        print_error "Failed to install Qt5 compatibility packages"
        exit 1
    fi

    # ESSENTIAL SYSTEM UTILITIES
    print_status "Installing essential system utilities..."
    if ! sudo pacman -S --needed --noconfirm \
        grim slurp wl-clipboard wtype \
        brightnessctl \
        mako libnotify \
        upower acpid \
        htop btop fastfetch \
        file-roller unzip zip 7zip \
        gvfs gvfs-mtp gvfs-gphoto2; then
        print_error "Failed to install essential system utilities"
        exit 1
    fi

    # MINIMAL FONTS AND THEMING
    print_status "Installing minimal fonts and theming..."
    if ! sudo pacman -S --needed --noconfirm \
        ttf-dejavu noto-fonts \
        papirus-icon-theme \
        gtk3 gtk4 adwaita-icon-theme; then
        print_error "Failed to install minimal theming packages"
        exit 1
    fi

    # DEVELOPMENT TOOLS AND BUILD DEPENDENCIES FOR QUICKSHELL
    print_status "Installing development tools and Quickshell build dependencies..."
    if ! sudo pacman -S --needed --noconfirm \
        cmake ninja pkgconf make gcc \
        git jemalloc cli11 \
        libdrm mesa vulkan-icd-loader vulkan-headers \
        libxcb xcb-util xcb-util-wm xcb-util-image \
        xcb-util-keysyms xcb-util-renderutil xcb-util-cursor \
        libxkbcommon libxkbcommon-x11 \
        libpipewire libglvnd \
        syntax-highlighting; then
        print_error "Failed to install development tools"
        exit 1
    fi

    # X11 COMPATIBILITY AND XWAYLAND
    print_status "Installing X11 compatibility layer..."
    if ! sudo pacman -S --needed --noconfirm \
        xorg-xwayland xorg-xlsclients xorg-xrandr \
        xorg-xinput xorg-xdpyinfo \
        libx11 libxcomposite libxcursor libxdamage \
        libxext libxfixes libxi libxinerama \
        libxrandr libxrender libxss libxtst; then
        print_error "Failed to install X11 compatibility packages"
        exit 1
    fi

    # ESSENTIAL DESKTOP UTILITIES - Let user choose apps
    print_status "Installing essential desktop utilities..."
    if ! sudo pacman -S --needed --noconfirm \
        thunar thunar-volman thunar-archive-plugin \
        wofi rofi-wayland \
        lxqt-policykit; then
        print_error "Failed to install desktop utilities"
        exit 1
    fi

    print_success "Official packages installed successfully"

    # Install critical AUR dependencies first
    print_status "Installing critical AUR dependencies..."
    if ! yay -S --needed --noconfirm google-breakpad; then
        print_warning "Failed to install google-breakpad, trying to continue anyway..."
    fi

    # Install Quickshell from AUR with fallback to prebuilt package
    print_status "Installing Quickshell from AUR..."
    quickshell_installed=false
    
    if yay -S --needed --noconfirm quickshell; then
        print_success "Quickshell installed successfully from AUR"
        quickshell_installed=true
    else
        print_warning "AUR installation failed, trying prebuilt package..."
        if [ -d "ArchPackages" ] && [ -n "$(ls ArchPackages/*.pkg.tar.* 2>/dev/null)" ]; then
            print_status "Installing prebuilt Quickshell package..."
            print_status "Found packages: $(ls ArchPackages/*.pkg.tar.*)"
            if sudo pacman -U --needed --noconfirm ArchPackages/quickshell*.pkg.tar.*; then
                print_success "Quickshell installed successfully from prebuilt package"
                quickshell_installed=true
            else
                print_warning "Failed to install prebuilt package"
            fi
        else
            print_warning "No prebuilt packages found in ArchPackages folder"
            print_status "Checking ArchPackages directory contents:"
            if [ -d "ArchPackages" ]; then
                ls -la ArchPackages/
            else
                print_warning "ArchPackages directory doesn't exist"
            fi
        fi
    fi
    
    # Final check
    if [ "$quickshell_installed" = false ]; then
        print_error "Failed to install Quickshell from both AUR and prebuilt packages"
        print_error "This could be due to:"
        print_error "1. Missing build dependencies (cmake, ninja, qt6 dev packages)"
        print_error "2. Network issues during git clone"
        print_error "3. Compilation errors"
        print_error "4. No prebuilt packages available"
        print_error ""
        print_error "Manual solutions:"
        print_error "1. Add a prebuilt quickshell package to ArchPackages/ folder"
        print_error "2. Try building from source manually"
        print_error "3. Check AUR for alternative quickshell packages"
        exit 1
    fi

    # Install remaining AUR packages
    print_status "Installing additional AUR packages..."
    declare -a aur_packages=(
        "matugen-bin"
        "grimblast"
        "hyprswitch"
        "nwg-displays"
        "nwg-look"
        "swww"
        "hypridle"
        "hyprlock"
        "hyprpaper"
        "hyprpicker"
        "wlogout"
        "better-control"
    )
    
    failed_packages=()
    for package in "${aur_packages[@]}"; do
        print_status "Installing $package..."
        if ! yay -S --needed --noconfirm "$package"; then
            print_warning "Failed to install $package"
            failed_packages+=("$package")
        else
            print_success "$package installed successfully"
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        print_warning "The following AUR packages failed to install:"
        for pkg in "${failed_packages[@]}"; do
            print_warning "  - $pkg"
        done
        print_warning "You can try installing these packages manually later:"
        printf 'yay -S %s\n' "${failed_packages[@]}"
        
        read -p "Continue anyway? [y/N]: " continue_choice
        if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "All AUR packages installed successfully"
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
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
    gtk-update-icon-cache -f -t /usr/share/icons/Papirus 2>/dev/null || true
    
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