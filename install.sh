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
            "arch")
                DISTRO="arch"
                print_status "Detected: Arch Linux"
                ;;
            *)
                print_error "Unsupported distribution: $PRETTY_NAME"
                print_error "This script supports:"
                print_error "- Arch Linux"
                print_error "- PikaOS 4 (Debian-based)"
                exit 1
                ;;
        esac
    elif command -v pacman &> /dev/null; then
        DISTRO="arch"
        print_status "Detected: Arch Linux (fallback detection)"
    else
        print_error "Unable to detect supported distribution"
        print_error "This script supports:"
        print_error "- Arch Linux"
        print_error "- PikaOS 4 (Debian-based)"
        exit 1
    fi
}

# Check distribution compatibility
check_distribution() {
    detect_distribution
    
    if [[ "$DISTRO" == "arch" ]]; then
        if ! command -v pacman &> /dev/null; then
            print_error "Arch Linux detected but pacman not found"
            exit 1
        fi
    elif [[ "$DISTRO" == "pikaos" ]]; then
        if ! command -v apt &> /dev/null; then
            print_error "PikaOS detected but apt not found"
            exit 1
        fi
        # Check if Quickshell is available (should be on PikaOS Hyprland edition)
        if ! dpkg -l | grep -q quickshell 2>/dev/null && ! command -v quickshell &> /dev/null; then
            print_warning "Quickshell not detected on PikaOS"
            print_warning "Please ensure you're using PikaOS Hyprland Edition, or install quickshell manually"
        fi
    fi
}

# Check internet connectivity
print_status "Checking internet connectivity..."
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    print_error "No internet connection detected. Please check your network and try again."
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
            if git clone https://aur.archlinux.org/yay-bin.git; then
                break
            else
                retry_count=$((retry_count + 1))
                print_warning "Git clone failed, attempt $retry_count/3"
                sleep 2
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

    # Install all required packages from official repositories
    print_status "Installing required packages from official repositories..."
    if ! sudo pacman -S --needed --noconfirm \
        hyprland wayland wayland-protocols xdg-desktop-portal-hyprland \
        pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber pamixer \
        networkmanager nm-connection-editor sddm \
        qt6-base qt6-declarative qt6-wayland qt6-svg qt6-imageformats qt6-multimedia \
        qt6-positioning qt6-quicktimeline qt6-sensors qt6-tools qt6-translations \
        qt6-virtualkeyboard qt6-5compat \
        qt5-base qt5-declarative qt5-graphicaleffects qt5-imageformats qt5-svg qt5-translations \
        grim slurp wl-clipboard wtype brightnessctl pamixer mako syntax-highlighting \
        ttf-dejavu noto-fonts; then
        print_error "Failed to install required packages from official repositories"
        exit 1
    fi

    print_success "Official packages installed successfully"

    # Install AUR packages
    print_status "Installing AUR packages..."
    if ! yay -S --needed --noconfirm \
        quickshell-git matugen-bin grimblast hyprswitch nwg-displays nwg-look; then
        print_error "Failed to install AUR packages"
        print_warning "You can try installing these packages manually later:"
        print_warning "yay -S quickshell-git matugen-bin grimblast hyprswitch nwg-displays nwg-look"
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
    if command -v quickshell &> /dev/null || dpkg -l | grep -q quickshell 2>/dev/null; then
        print_success "Quickshell is already available on PikaOS"
    else
        print_warning "Quickshell not found. Installing via pikman (if available)..."
        if command -v pikman &> /dev/null; then
            pikman install quickshell
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

# Install packages based on distribution
if [[ "$DISTRO" == "arch" ]]; then
    install_arch_packages
elif [[ "$DISTRO" == "pikaos" ]]; then
    install_pikaos_packages
fi

# Clone the configuration repository
print_status "Cloning Matt's Quickshell Hyprland configuration..."
if [ -d "/tmp/Matts-Quickshell-Hyprland" ]; then
    rm -rf /tmp/Matts-Quickshell-Hyprland
fi

cd /tmp

# Clone with retry mechanism
retry_count=0
while [ $retry_count -lt 3 ]; do
    if git clone https://github.com/ryzendew/Matts-Quickshell-Hyprland.git; then
        break
    else
        retry_count=$((retry_count + 1))
        print_warning "Git clone failed, attempt $retry_count/3"
        sleep 2
    fi
done

if [ $retry_count -eq 3 ]; then
    print_error "Failed to clone configuration repository after 3 attempts"
    print_error "Please check your internet connection and try again"
    exit 1
fi

cd Matts-Quickshell-Hyprland

# Copy configuration files
print_status "Installing configuration files..."
if ! mkdir -p "$HOME/.config" 2>/dev/null; then
    print_error "Failed to create .config directory"
    exit 1
fi

if ! cp -r .config/* "$HOME/.config/" 2>/dev/null; then
    print_error "Failed to copy configuration files"
    print_error "This could be due to permission issues or disk space"
    exit 1
fi

# Make scripts executable
print_status "Setting up executable permissions..."
find "$HOME/.config" -name "*.sh" -type f -exec chmod +x {} \;
find "$HOME/.config" -name "*.py" -type f -exec chmod +x {} \;

print_success "Configuration files installed successfully"

# Weather location configuration
echo
print_status "Weather Configuration:"
echo "The weather widget needs your location to show accurate weather data."
echo "Enter your location (city, state/province, country):"
echo "Examples: 'New York, NY, USA' or 'London, England' or 'Tokyo, Japan'"
read -p "Your location [default: Halifax, Nova Scotia, Canada]: " user_location

if [[ -z "$user_location" ]]; then
    user_location="Halifax, Nova Scotia, Canada"
    print_status "Using default location: $user_location"
else
    print_status "Setting weather location to: $user_location"
    
    # Update weather configuration files with error handling
    print_status "Updating weather configuration files..."
    weather_update_errors=0
    
    # Update WeatherModule.qml
    if [ -f "$HOME/.config/quickshell/modules/bar/modules/WeatherModule.qml" ]; then
        if ! sed -i "s/weatherLocation: \".*\"/weatherLocation: \"$user_location\"/" "$HOME/.config/quickshell/modules/bar/modules/WeatherModule.qml" 2>/dev/null; then
            print_warning "Failed to update WeatherModule.qml"
            weather_update_errors=$((weather_update_errors + 1))
        fi
    else
        print_warning "WeatherModule.qml not found"
        weather_update_errors=$((weather_update_errors + 1))
    fi
    
    # Update Weather.qml
    if [ -f "$HOME/.config/quickshell/modules/bar/Weather.qml" ]; then
        if ! sed -i "s/property string weatherLocation: \".*\"/property string weatherLocation: \"$user_location\"/" "$HOME/.config/quickshell/modules/bar/Weather.qml" 2>/dev/null; then
            print_warning "Failed to update Weather.qml"
            weather_update_errors=$((weather_update_errors + 1))
        fi
    else
        print_warning "Weather.qml not found"
        weather_update_errors=$((weather_update_errors + 1))
    fi
    
    # Update WeatherForecast.qml
    if [ -f "$HOME/.config/quickshell/modules/weather/WeatherForecast.qml" ]; then
        if ! sed -i "s/property string weatherLocation: \".*\"/property string weatherLocation: \"$user_location\"/" "$HOME/.config/quickshell/modules/weather/WeatherForecast.qml" 2>/dev/null; then
            print_warning "Failed to update WeatherForecast.qml"
            weather_update_errors=$((weather_update_errors + 1))
        fi
    else
        print_warning "WeatherForecast.qml not found"
        weather_update_errors=$((weather_update_errors + 1))
    fi
    
    if [ $weather_update_errors -eq 0 ]; then
        print_success "Weather location configured successfully"
    else
        print_warning "Some weather configuration files could not be updated"
        print_warning "You may need to manually update the weather location in the QML files"
    fi
fi

# Optional: Install additional useful packages
echo
print_status "Additional recommended packages:"
echo "Do you want to install additional recommended packages?"
echo "This includes: file manager (nautilus)"
read -p "Install additional packages? [y/N]: " additional_choice

if [[ $additional_choice =~ ^[Yy]$ ]]; then
    print_status "Installing additional packages..."
    if [[ "$DISTRO" == "arch" ]]; then
        sudo pacman -S --needed --noconfirm \
            nautilus file-roller
    elif [[ "$DISTRO" == "pikaos" ]]; then
        sudo apt install -y \
            nautilus file-roller
    fi
    print_success "Additional packages installed"
fi

# Terminal selection
echo
print_status "Terminal Selection:"
echo "Which terminal emulator would you like to install?"
echo "1) Alacritty (recommended)"
echo "2) Ptyxis (GNOME Console)"
echo "3) Ghostty"
echo "4) Kitty"
echo "5) Wezterm"
echo "6) Foot"
echo "7) Terminator"
echo "8) GNOME Terminal"
echo "9) Skip terminal installation"
echo
read -p "Enter your choice [1-9]: " terminal_choice

# Validate terminal choice
if [[ ! "$terminal_choice" =~ ^[1-9]$ ]]; then
    print_warning "Invalid choice. Defaulting to Alacritty"
    terminal_choice=1
fi

# Distribution-specific terminal installation
install_terminal() {
    local terminal=$1
    local package_name=$2
    local is_aur=$3
    
    if [[ "$DISTRO" == "arch" ]]; then
        if [[ "$is_aur" == "true" ]]; then
            print_status "Installing $terminal (from AUR)..."
            yay -S --needed --noconfirm "$package_name"
        else
            print_status "Installing $terminal..."
            sudo pacman -S --needed --noconfirm "$package_name"
        fi
    elif [[ "$DISTRO" == "pikaos" ]]; then
        case "$terminal" in
            "Alacritty"|"Kitty"|"Foot"|"Terminator"|"GNOME Terminal")
                print_status "Installing $terminal..."
                sudo apt install -y "$package_name"
                ;;
            "Ptyxis"|"Ghostty"|"Wezterm")
                print_status "Installing $terminal..."
                if command -v pikman &> /dev/null; then
                    pikman install "$package_name" || {
                        print_warning "$terminal may not be available on PikaOS"
                        print_warning "Falling back to Alacritty..."
                        sudo apt install -y alacritty
                    }
                else
                    print_warning "$terminal not available via apt, falling back to Alacritty..."
                    sudo apt install -y alacritty
                fi
                ;;
        esac
    fi
}

case $terminal_choice in
    1)
        install_terminal "Alacritty" "alacritty" "false"
        print_success "Alacritty installed"
        ;;
    2)
        if [[ "$DISTRO" == "arch" ]]; then
            install_terminal "Ptyxis" "ptyxis" "true"
            print_status "Installing Ptyxis Nautilus extensions..."
            yay -S --needed --noconfirm nautilus-open-in-ptyxis nautilus-admin-gtk4
        else
            install_terminal "Ptyxis" "ptyxis" "true"
        fi
        print_success "Ptyxis installed"
        ;;
    3)
        install_terminal "Ghostty" "ghostty" "true"
        print_success "Ghostty installed"
        ;;
    4)
        install_terminal "Kitty" "kitty" "false"
        print_success "Kitty installed"
        ;;
    5)
        install_terminal "Wezterm" "wezterm" "true"
        print_success "Wezterm installed"
        ;;
    6)
        install_terminal "Foot" "foot" "false"
        print_success "Foot installed"
        ;;
    7)
        install_terminal "Terminator" "terminator" "false"
        print_success "Terminator installed"
        ;;
    8)
        install_terminal "GNOME Terminal" "gnome-terminal" "false"
        print_success "GNOME Terminal installed"
        ;;
    9)
        print_status "Skipping terminal installation"
        ;;
    *)
        print_warning "Invalid choice. Skipping terminal installation"
        ;;
esac

# Browser selection
echo
print_status "Browser Selection:"
echo "Which web browser would you like to install?"
echo "1) Firefox (recommended)"
echo "2) Google Chrome"
echo "3) Microsoft Edge Dev"
echo "4) Microsoft Edge Stable"
echo "5) Brave Browser"
echo "6) Chromium"
echo "7) Vivaldi"
echo "8) Opera"
echo "9) Skip browser installation"
echo
read -p "Enter your choice [1-9]: " browser_choice

# Validate browser choice
if [[ ! "$browser_choice" =~ ^[1-9]$ ]]; then
    print_warning "Invalid choice. Defaulting to Firefox"
    browser_choice=1
fi

# Distribution-specific browser installation
install_browser() {
    local browser=$1
    local package_name=$2
    local is_aur=$3
    
    if [[ "$DISTRO" == "arch" ]]; then
        if [[ "$is_aur" == "true" ]]; then
            print_status "Installing $browser (from AUR)..."
            yay -S --needed --noconfirm "$package_name"
        else
            print_status "Installing $browser..."
            sudo pacman -S --needed --noconfirm "$package_name"
        fi
    elif [[ "$DISTRO" == "pikaos" ]]; then
        case "$browser" in
            "Firefox"|"Chromium")
                print_status "Installing $browser..."
                sudo apt install -y "$package_name"
                ;;
            "Google Chrome")
                print_status "Installing Google Chrome..."
                # Check if Chrome is available via pikman or install manually
                if command -v pikman &> /dev/null; then
                    pikman install google-chrome || {
                        print_warning "Installing Chrome via manual method..."
                        wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
                        echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
                        sudo apt update
                        sudo apt install -y google-chrome-stable
                    }
                else
                    print_warning "Installing Chrome via manual method..."
                    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
                    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
                    sudo apt update
                    sudo apt install -y google-chrome-stable
                fi
                ;;
            *)
                print_status "Installing $browser..."
                if command -v pikman &> /dev/null; then
                    pikman install "$package_name" || {
                        print_warning "$browser may not be available on PikaOS"
                        print_warning "Falling back to Firefox..."
                        sudo apt install -y firefox
                    }
                else
                    print_warning "$browser not available via apt, falling back to Firefox..."
                    sudo apt install -y firefox
                fi
                ;;
        esac
    fi
}

case $browser_choice in
    1)
        install_browser "Firefox" "firefox" "false"
        print_success "Firefox installed"
        ;;
    2)
        install_browser "Google Chrome" "google-chrome" "true"
        print_success "Google Chrome installed"
        ;;
    3)
        install_browser "Microsoft Edge Dev" "microsoft-edge-dev-bin" "true"
        print_success "Microsoft Edge Dev installed"
        ;;
    4)
        install_browser "Microsoft Edge Stable" "microsoft-edge-stable-bin" "true"
        print_success "Microsoft Edge Stable installed"
        ;;
    5)
        install_browser "Brave Browser" "brave-bin" "true"
        print_success "Brave Browser installed"
        ;;
    6)
        install_browser "Chromium" "chromium" "false"
        print_success "Chromium installed"
        ;;
    7)
        install_browser "Vivaldi" "vivaldi" "true"
        print_success "Vivaldi installed"
        ;;
    8)
        install_browser "Opera" "opera" "true"
        print_success "Opera installed"
        ;;
    9)
        print_status "Skipping browser installation"
        ;;
    *)
        print_warning "Invalid choice. Skipping browser installation"
        ;;
esac

# Cleanup
cd ~
rm -rf /tmp/Matts-Quickshell-Hyprland

echo
print_success "=============================================="
print_success "Installation completed successfully!"
print_success "=============================================="
echo
print_status "Next steps:"
echo "1. Reboot your system"
if [[ "$DISTRO" == "arch" ]]; then
    echo "2. Select Hyprland from your display manager (SDDM)"
elif [[ "$DISTRO" == "pikaos" ]]; then
    echo "2. Select Hyprland from your display manager (should already be available)"
fi
echo "3. Start Quickshell with: qs"
echo
print_status "Or start Quickshell now in the current session:"
echo "qs"
echo
print_status "Configuration location: ~/.config/quickshell/"
print_status "Hyprland config location: ~/.config/hypr/"
echo

if [[ "$DISTRO" == "pikaos" ]]; then
    print_status "PikaOS-specific notes:"
    echo "• Hyprland should already be configured optimally"
    echo "• Most dependencies were pre-installed"
    echo "• Use 'pikman' for additional packages when available"
    echo "• Gaming optimizations are built-in"
    echo
fi

print_warning "If you encounter any issues, check the troubleshooting section in the README"
echo

# Ask if user wants to start Quickshell now
read -p "Do you want to start Quickshell now? [y/N]: " start_choice
if [[ $start_choice =~ ^[Yy]$ ]]; then
    print_status "Starting Quickshell..."
    if command -v qs &> /dev/null; then
        qs &
        print_success "Quickshell started in background"
    elif command -v quickshell &> /dev/null; then
        quickshell &
        print_success "Quickshell started in background"
    else
        print_warning "Quickshell command not found. You may need to reboot first."
    fi
fi

print_success "Enjoy your new Quickshell Hyprland setup on $DISTRO!" 