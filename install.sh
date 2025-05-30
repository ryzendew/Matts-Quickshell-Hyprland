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
    
    print_success "Configuration files copied successfully (force overwritten, backups made)"
else
    print_error "Configuration directory not found!"
    exit 1
fi

# Distribution-specific package installation functions
install_arch_packages() {
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

    # Install all required packages from official repositories (including build deps)
    print_status "Installing required packages from official repositories..."
    if ! sudo pacman -S --needed --noconfirm \
        hyprland wayland wayland-protocols xdg-desktop-portal-hyprland \
        pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber pamixer \
        networkmanager nm-connection-editor sddm \
        qt6-base qt6-declarative qt6-wayland qt6-svg qt6-imageformats qt6-multimedia \
        qt6-positioning qt6-quicktimeline qt6-sensors qt6-tools qt6-translations \
        qt6-virtualkeyboard qt6-5compat qt6-shadertools \
        qt5-base qt5-declarative qt5-graphicaleffects qt5-imageformats qt5-svg qt5-translations \
        grim slurp wl-clipboard wtype brightnessctl pamixer mako syntax-highlighting \
        ttf-dejavu noto-fonts \
        cmake ninja pkgconf git jemalloc cli11 libdrm mesa libxcb libpipewire \
        xcb-util xcb-util-wm xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-cursor \
        libxcb-cursor libxkbcommon libxkbcommon-x11 \
        xorg-xwayland xorg-xlsclients xorg-xrandr \
        wayland-utils weston xdg-utils \
        vulkan-icd-loader vulkan-headers; then
        print_error "Failed to install required packages from official repositories"
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
    print_status "Installing remaining AUR packages..."
    if ! yay -S --needed --noconfirm \
        matugen-bin grimblast hyprswitch nwg-displays nwg-look; then
        print_warning "Failed to install some AUR packages"
        print_warning "You can try installing these packages manually later:"
        print_warning "yay -S matugen-bin grimblast hyprswitch nwg-displays nwg-look"
        read -p "Continue anyway? [y/N]: " continue_choice
        if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "AUR packages installed successfully"
    fi

    # Enable essential system services
    print_status "Enabling essential system services..."
    service_errors=0

    if ! sudo systemctl enable NetworkManager 2>/dev/null; then
        print_warning "Failed to enable NetworkManager"
        service_errors=$((service_errors + 1))
    fi

    if ! sudo systemctl enable sddm 2>/dev/null; then
        print_warning "Failed to enable SDDM"
        service_errors=$((service_errors + 1))
    fi

    if [ $service_errors -eq 0 ]; then
        print_success "System services enabled"
    else
        print_warning "$service_errors service(s) failed to enable. You may need to enable them manually later."
    fi
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