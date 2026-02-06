#!/usr/bin/env bash

#CarmonyOS Version 11.2 ! 

RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"
ITALIC="\e[3m"
UNDERLINE="\e[4m"

BLACK="\e[38;5;0m"
RED="\e[38;5;196m"
GREEN="\e[38;5;82m"
YELLOW="\e[38;5;226m"
BLUE="\e[38;5;39m"
MAGENTA="\e[38;5;201m"
CYAN="\e[38;5;51m"
WHITE="\e[38;5;255m"
ORANGE="\e[38;5;208m"
PINK="\e[38;5;213m"
PURPLE="\e[38;5;141m"
LIME="\e[38;5;154m"
TEAL="\e[38;5;30m"
GRAY="\e[38;5;245m"
DARK_GRAY="\e[38;5;238m"
LIGHT_BLUE="\e[38;5;117m"
GOLD="\e[38;5;220m"

VERSION="11.2"
CODENAME="CarmonyOS Edition"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
LOCAL_SHARE_DIR="$HOME/.local/share"
BACKUP_DIR="$HOME/.CarmonyOS-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/tmp/CarmonyOS-Installer-$(date +%Y%m%d-%H%M%S).log"

SELECTED_DISTRO=""
INSTALL_GUI_DEPS=false
CUSTOM_PACKAGES=""
LAUNCHER_TYPE=""
HAS_YAY=false

touch "$LOG_FILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

clear_screen() {
    printf "\033c"
    printf "\e[3J"
}

get_terminal_size() {
    TERM_COLS=$(tput cols 2>/dev/null || echo 80)
    TERM_ROWS=$(tput lines 2>/dev/null || echo 24)
}

print_centered() {
    local text="$1"
    local color="${2:-$WHITE}"
    get_terminal_size
    local clean_text
    clean_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_length=${#clean_text}
    local padding=$(( (TERM_COLS - text_length) / 2 ))
    [[ $padding -lt 0 ]] && padding=0
    printf "%${padding}s${color}%s${RESET}\n" "" "$text"
}

print_gradient_line() {
    get_terminal_size
    local colors=(196 202 208 214 220 226 190 154 118 82 46 47 48 49 50 51 45 39 33 27 21 57 93 129 165 201 200 199 198 197)
    local line=""
    for ((i=0; i<TERM_COLS; i++)); do
        local color_index=$((i % ${#colors[@]}))
        line+="\e[38;5;${colors[$color_index]}m━"
    done
    echo -e "${line}${RESET}"
}

print_sparkle_line() {
    get_terminal_size
    local chars=("✦" "✧" "◆" "◇" "●" "○" "★" "☆")
    local colors=(201 213 219 225 231 225 219 213)
    local line=""
    for ((i=0; i<TERM_COLS/2; i++)); do
        local char_index=$((i % ${#chars[@]}))
        local color_index=$((i % ${#colors[@]}))
        line+="\e[38;5;${colors[$color_index]}m${chars[$char_index]} "
    done
    echo -e "${line}${RESET}"
}

print_wave_line() {
    get_terminal_size
    local colors=(39 45 51 50 49 48 47 46 82 118 154 190 226 220 214 208 202 196)
    local line=""
    for ((i=0; i<TERM_COLS; i++)); do
        local color_index=$((i % ${#colors[@]}))
        line+="\e[38;5;${colors[$color_index]}m▀"
    done
    echo -e "${line}${RESET}"
}

print_box() {
    local title="$1"
    local color="${2:-$CYAN}"
    get_terminal_size
    local width=$((TERM_COLS - 4))
    [[ $width -lt 40 ]] && width=40
    
    printf "  ${color}╭"
    for ((i=0; i<width; i++)); do printf "─"; done
    printf "╮${RESET}\n"
    
    if [[ -n "$title" ]]; then
        local title_clean
        title_clean=$(echo -e "$title" | sed 's/\x1b\[[0-9;]*m//g')
        local title_len=${#title_clean}
        local left_pad=$(( (width - title_len - 2) / 2 ))
        local right_pad=$((width - title_len - 2 - left_pad))
        [[ $left_pad -lt 0 ]] && left_pad=0
        [[ $right_pad -lt 0 ]] && right_pad=0
        printf "  ${color}│${RESET}"
        printf "%${left_pad}s" ""
        printf " ${BOLD}%s${RESET} " "$title"
        printf "%${right_pad}s" ""
        printf "${color}│${RESET}\n"
        printf "  ${color}├"
        for ((i=0; i<width; i++)); do printf "─"; done
        printf "┤${RESET}\n"
    fi
}

print_box_content() {
    local text="$1"
    local color="${2:-$CYAN}"
    get_terminal_size
    local width=$((TERM_COLS - 4))
    [[ $width -lt 40 ]] && width=40
    local text_clean
    text_clean=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_len=${#text_clean}
    local padding=$((width - text_len - 2))
    [[ $padding -lt 0 ]] && padding=0
    printf "  ${color}│${RESET} "
    echo -en "$text"
    printf "%${padding}s" ""
    printf " ${color}│${RESET}\n"
}

print_box_center() {
    local text="$1"
    local text_color="${2:-$WHITE}"
    local border_color="${3:-$CYAN}"
    get_terminal_size
    local width=$((TERM_COLS - 4))
    [[ $width -lt 40 ]] && width=40
    local text_clean
    text_clean=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_len=${#text_clean}
    local left_pad=$(( (width - text_len) / 2 ))
    local right_pad=$((width - text_len - left_pad))
    [[ $left_pad -lt 0 ]] && left_pad=0
    [[ $right_pad -lt 0 ]] && right_pad=0
    printf "  ${border_color}│${RESET}"
    printf "%${left_pad}s" ""
    printf "${text_color}%s${RESET}" "$text"
    printf "%${right_pad}s" ""
    printf "${border_color}│${RESET}\n"
}

print_box_empty() {
    local color="${1:-$CYAN}"
    get_terminal_size
    local width=$((TERM_COLS - 4))
    [[ $width -lt 40 ]] && width=40
    printf "  ${color}│${RESET}"
    printf "%${width}s" ""
    printf "${color}│${RESET}\n"
}

print_box_separator() {
    local color="${1:-$CYAN}"
    get_terminal_size
    local width=$((TERM_COLS - 4))
    [[ $width -lt 40 ]] && width=40
    printf "  ${color}├"
    for ((i=0; i<width; i++)); do printf "─"; done
    printf "┤${RESET}\n"
}

print_box_double_separator() {
    local color="${1:-$CYAN}"
    get_terminal_size
    local width=$((TERM_COLS - 4))
    [[ $width -lt 40 ]] && width=40
    printf "  ${color}╞"
    for ((i=0; i<width; i++)); do printf "═"; done
    printf "╡${RESET}\n"
}

print_box_end() {
    local color="${1:-$CYAN}"
    get_terminal_size
    local width=$((TERM_COLS - 4))
    [[ $width -lt 40 ]] && width=40
    printf "  ${color}╰"
    for ((i=0; i<width; i++)); do printf "─"; done
    printf "╯${RESET}\n"
}

print_logo() {
    echo ""
    echo -e "${PURPLE}${BOLD}"
    
print_centerd"   ██████╗ █████╗ ██████╗ ███╗   ███╗ ██████╗ ███╗   ██╗██╗   ██╗ ██████╗ ███████╗"
print_centerd"  ██╔════╝██╔══██╗██╔══██╗████╗ ████║██╔═══██╗████╗  ██║╚██╗ ██╔╝██╔═══██╗██╔════╝"
print_centerd" ██║     ███████║██████╔╝██╔████╔██║██║   ██║██╔██╗ ██║ ╚████╔╝ ██║   ██║███████╗"
print_centerd"  ██║     ██╔══██║██╔══██╗██║╚██╔╝██║██║   ██║██║╚██╗██║  ╚██╔╝  ██║   ██║╚════██║"
print_centerd"  ╚██████╗██║  ██║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║ ╚████║   ██║   ╚██████╔╝███████║"
print_centerd"   ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚══════╝"
    echo -e "${RESET}"
    echo ""
    print_gradient_line
    echo ""
    print_centered "✦ M A N A G E R ✦" "${BOLD}${CYAN}"
    print_centered "Version ${VERSION} │ ${CODENAME}" "${DIM}${WHITE}"
    echo ""
    print_gradient_line
    echo ""
}

print_mini_logo() {
    echo ""
    echo -e "${PURPLE}${BOLD}"
    print_centered "CARMONY/UI"
    print_centered "CONFIG FILE FOR LINUX"
    echo -e "${RESET}"
    print_centered "━━━━━━━━━━━━━━━━━━━━━━━━━━━" "${PURPLE}"
    print_centered "v${VERSION} │ ${CODENAME}" "${DIM}${GRAY}"
    echo ""
}

print_success() {
    echo -e "  ${GREEN}${BOLD}  ✔ ${RESET}${GREEN}$1${RESET}"
}

print_error() {
    echo -e "  ${RED}${BOLD}  ✖ ${RESET}${RED}$1${RESET}"
    log "ERROR: $1"
}

print_warning() {
    echo -e "  ${YELLOW}${BOLD}  ⚠ ${RESET}${YELLOW}$1${RESET}"
    log "WARNING: $1"
}

print_info() {
    echo -e "  ${BLUE}${BOLD}  ℹ ${RESET}${BLUE}$1${RESET}"
}

print_step() {
    echo -e "  ${MAGENTA}${BOLD}  ➤ ${RESET}${WHITE}$1${RESET}"
    log "STEP: $1"
}

print_package() {
    echo -e "  ${CYAN}${BOLD}  📦 ${RESET}${WHITE}$1${RESET}"
}

print_font() {
    echo -e "  ${PINK}${BOLD}  🔤 ${RESET}${WHITE}$1${RESET}"
}

print_shortcut() {
    local key="$1"
    local desc="$2"
    local color="${3:-$CYAN}"
    echo -e "  ${color}${BOLD}  ⌨  ${RESET}${GOLD}${BOLD}$key${RESET}  ${GRAY}→  ${WHITE}$desc${RESET}"
}

spinner() {
    local pid=$1
    local message="$2"
    local frames=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
    local colors=(201 207 213 219 225 219 213 207)
    local i=0
    
    tput civis 2>/dev/null || true
    
    while kill -0 "$pid" 2>/dev/null; do
        local frame="${frames[$((i % ${#frames[@]}))]}"
        local color="${colors[$((i % ${#colors[@]}))]}"
        printf "\r  \e[38;5;${color}m${BOLD}${frame}${RESET} ${WHITE}%s${RESET}   " "$message"
        sleep 0.1
        ((i++)) || true
    done
    
    tput cnorm 2>/dev/null || true
    printf "\r%80s\r" ""
}

fancy_spinner() {
    local pid=$1
    local message="$2"
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local braille=('⣿' '⣷' '⣯' '⣟' '⡿' '⢿' '⣻' '⣽')
    local dots=('   ' '.  ' '.. ' '...')
    local i=0
    
    tput civis 2>/dev/null || true
    
    while kill -0 "$pid" 2>/dev/null; do
        local frame="${frames[$((i % ${#frames[@]}))]}"
        local dot="${dots[$((i / 3 % ${#dots[@]}))]}"
        local color=$((201 + (i % 30)))
        printf "\r  \e[38;5;${color}m${BOLD}${frame}${RESET} ${WHITE}%s${RESET}${GRAY}%s${RESET}   " "$message" "$dot"
        sleep 0.08
        ((i++)) || true
    done
    
    tput cnorm 2>/dev/null || true
    printf "\r%100s\r" ""
}

progress_bar() {
    local current=$1
    local total=$2
    local message="$3"
    local width=30
    
    [[ $total -eq 0 ]] && total=1
    
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    local bar_colors=(201 199 197 196 202 208 214 220)
    
    printf "\r  ${PURPLE}▐${RESET}"
    
    for ((i=0; i<filled; i++)); do
        local color_idx=$((i * ${#bar_colors[@]} / width))
        printf "\e[38;5;${bar_colors[$color_idx]}m█${RESET}"
    done
    
    for ((i=0; i<empty; i++)); do
        printf "${DARK_GRAY}░${RESET}"
    done
    
    printf "${PURPLE}▌${RESET} ${BOLD}${WHITE}%3d%%${RESET} ${GRAY}%-30s${RESET}" "$percent" "$message"
}

confirm_action() {
    local message="$1"
    local default="${2:-n}"
    local response
    
    if [[ "$default" == "y" ]]; then
        local prompt="${GREEN}Y${RESET}/${DIM}n${RESET}"
    else
        local prompt="${DIM}y${RESET}/${GREEN}N${RESET}"
    fi
    
    echo ""
    echo -e "  ${PURPLE}╭────────────────────────────────────────────────────────────────╮${RESET}"
    echo -e "  ${PURPLE}│${RESET} ${YELLOW}${BOLD}?${RESET} ${WHITE}$message${RESET}"
    echo -e "  ${PURPLE}╰────────────────────────────────────────────────────────────────╯${RESET}"
    printf "  ${CYAN}${BOLD}    ➤ Your choice [${prompt}${CYAN}${BOLD}]: ${RESET}"
    read -r response
    
    response=${response:-$default}
    [[ "$response" =~ ^[Yy]$ ]]
}

select_option() {
    local message="$1"
    shift
    local options=("$@")
    local choice
    
    echo ""
    echo -e "  ${BLUE}╭────────────────────────────────────────────────────────────────╮${RESET}"
    echo -e "  ${BLUE}│${RESET} ${CYAN}${BOLD}◆${RESET} ${WHITE}$message${RESET}"
    echo -e "  ${BLUE}├────────────────────────────────────────────────────────────────┤${RESET}"
    
    local i=1
    for opt in "${options[@]}"; do
        echo -e "  ${BLUE}│${RESET}   ${GREEN}${BOLD}[$i]${RESET} ${WHITE}$opt${RESET}"
        ((i++))
    done
    
    echo -e "  ${BLUE}╰────────────────────────────────────────────────────────────────╯${RESET}"
    printf "  ${CYAN}${BOLD}    ➤ Select [1-${#options[@]}]: ${RESET}"
    read -r choice
    
    echo "$choice"
}

get_input() {
    local message="$1"
    local default="$2"
    local response
    
    echo ""
    echo -e "  ${BLUE}╭────────────────────────────────────────────────────────────────╮${RESET}"
    echo -e "  ${BLUE}│${RESET} ${CYAN}${BOLD}✎${RESET} ${WHITE}$message${RESET}"
    echo -e "  ${BLUE}╰────────────────────────────────────────────────────────────────╯${RESET}"
    printf "  ${CYAN}${BOLD}    ➤ Input: ${RESET}"
    read -r response
    
    echo "${response:-$default}"
}

check_yay() {
    if command -v yay &>/dev/null; then
        HAS_YAY=true
        log "yay detected"
        return 0
    else
        HAS_YAY=false
        log "yay not found"
        return 1
    fi
}

show_main_menu() {
    clear_screen
    print_logo
    
    print_box "🎯 SELECT YOUR DISTRIBUTION" "$PURPLE"
    print_box_empty "$PURPLE"
    print_box_content "${GREEN}${BOLD}  [1]${RESET}  ${CYAN}🏔️ ${RESET} ${WHITE}${BOLD}Arch Linux${RESET}       ${DIM}Full install + gnome-disk-utility${RESET}" "$PURPLE"
    print_box_empty "$PURPLE"
    print_box_content "${GREEN}${BOLD}  [2]${RESET}  ${ORANGE}🟠${RESET}  ${WHITE}${BOLD}Ubuntu${RESET}           ${DIM}Full installation with apt${RESET}" "$PURPLE"
    print_box_empty "$PURPLE"
    print_box_content "${GREEN}${BOLD}  [3]${RESET}  ${BLUE}🎩${RESET}  ${WHITE}${BOLD}Fedora${RESET}           ${DIM}Full installation with dnf${RESET}" "$PURPLE"
    print_box_empty "$PURPLE"
    print_box_content "${GREEN}${BOLD}  [4]${RESET}  ${MAGENTA}💎${RESET}  ${WHITE}${BOLD}Omarchy${RESET}          ${DIM}Configs only - already set up!${RESET}" "$PURPLE"
    print_box_empty "$PURPLE"
    print_box_separator "$PURPLE"
    print_box_content "${RED}${BOLD}  [5]${RESET}  ${RED}🚪${RESET}  ${WHITE}${BOLD}Exit${RESET}             ${DIM}Close OmGlass Manager${RESET}" "$PURPLE"
    print_box_empty "$PURPLE"
    print_box_end "$PURPLE"
    
    echo ""
    echo -e "  ${DIM}Tip: Type 'about' for more information${RESET}"
    echo ""
    printf "  ${MAGENTA}${BOLD}  ✦ Enter your choice [1-5]: ${RESET}"
}

ask_launcher_type() {
    echo ""
    print_box "🚀 APPLICATION LAUNCHER" "$CYAN"
    print_box_empty "$CYAN"
    print_box_content "${WHITE}Which application launcher do you prefer?${RESET}" "$CYAN"
    print_box_empty "$CYAN"
    print_box_content "${GREEN}${BOLD}  [1]${RESET}  ${CYAN}🔍${RESET} ${WHITE}${BOLD}Rofi${RESET}      ${DIM}Classic & highly customizable${RESET}" "$CYAN"
    print_box_empty "$CYAN"
    print_box_content "${GREEN}${BOLD}  [2]${RESET}  ${MAGENTA}🎯${RESET} ${WHITE}${BOLD}Wofi${RESET}      ${DIM}Native Wayland, lightweight${RESET}" "$CYAN"
    print_box_empty "$CYAN"
    print_box_content "${GREEN}${BOLD}  [3]${RESET}  ${YELLOW}⚡${RESET} ${WHITE}${BOLD}Walker${RESET}    ${DIM}Modern GTK4 launcher${RESET}" "$CYAN"
    print_box_empty "$CYAN"
    print_box_content "${GREEN}${BOLD}  [4]${RESET}  ${GRAY}⏭️ ${RESET} ${WHITE}${BOLD}Skip${RESET}      ${DIM}I'll configure it myself${RESET}" "$CYAN"
    print_box_empty "$CYAN"
    print_box_end "$CYAN"
    
    printf "\n  ${CYAN}${BOLD}    ➤ Select launcher [1-4]: ${RESET}"
    read -r choice
    
    case "$choice" in
        1) LAUNCHER_TYPE="rofi" ;;
        2) LAUNCHER_TYPE="wofi" ;;
        3) LAUNCHER_TYPE="walker" ;;
        4) LAUNCHER_TYPE="skip" ;;
        *) LAUNCHER_TYPE="wofi" ;;
    esac
    
    if [[ "$LAUNCHER_TYPE" != "skip" ]]; then
        print_success "Selected launcher: ${BOLD}$LAUNCHER_TYPE${RESET}"
    else
        print_info "Skipping launcher selection"
    fi
}

show_package_preview() {
    local distro="$1"
    
    clear_screen
    print_mini_logo
    
    print_box "📦 PACKAGES FOR ${distro^^}" "$CYAN"
    print_box_empty "$CYAN"
    print_box_content "${MAGENTA}●${RESET} ${WHITE}${BOLD}Window Manager${RESET}      ${GRAY}hyprland${RESET}" "$CYAN"
    print_box_content "${MAGENTA}●${RESET} ${WHITE}${BOLD}Lock & Idle${RESET}         ${GRAY}hyprlock, hypridle${RESET}" "$CYAN"
    print_box_content "${MAGENTA}●${RESET} ${WHITE}${BOLD}Night Light${RESET}         ${GRAY}hyprsunset${RESET}" "$CYAN"
    print_box_content "${MAGENTA}●${RESET} ${WHITE}${BOLD}Status Bar${RESET}          ${GRAY}waybar${RESET}" "$CYAN"
    print_box_content "${MAGENTA}●${RESET} ${WHITE}${BOLD}Wallpaper Engine${RESET}    ${GRAY}swww${RESET}" "$CYAN"
    print_box_content "${MAGENTA}●${RESET} ${WHITE}${BOLD}Terminal${RESET}            ${GRAY}kitty${RESET}" "$CYAN"
    print_box_content "${MAGENTA}●${RESET} ${WHITE}${BOLD}File Manager${RESET}        ${GRAY}thunar${RESET}" "$CYAN"
    print_box_content "${MAGENTA}●${RESET} ${WHITE}${BOLD}Launcher${RESET}            ${GRAY}rofi${RESET}" "$CYAN"
    print_box_content "${MAGENTA}●${RESET} ${WHITE}${BOLD}Media Player${RESET}        ${GRAY}mpv${RESET}" "$CYAN"
    print_box_content "${MAGENTA}●${RESET} ${WHITE}${BOLD}Image Viewer${RESET}        ${GRAY}imv${RESET}" "$CYAN"
    print_box_content "${MAGENTA}●${RESET} ${WHITE}${BOLD}System Monitor${RESET}      ${GRAY}btop${RESET}" "$CYAN"
    print_box_content "${MAGENTA}●${RESET} ${WHITE}${BOLD}Utilities${RESET}           ${GRAY}jq, imagemagick, gtk3, gtk4${RESET}" "$CYAN"
    print_box_separator "$CYAN"
    print_box_content "${PINK}●${RESET} ${WHITE}${BOLD}Fonts${RESET}               ${GRAY}JetBrains Mono Nerd Font${RESET}" "$CYAN"
    
    if [[ "$distro" == "Arch Linux" ]]; then
        print_box_content "${GREEN}●${RESET} ${WHITE}${BOLD}Disk Manager${RESET}        ${GRAY}gnome-disk-utility (Arch only)${RESET}" "$CYAN"
        if check_yay; then
            print_box_content "${YELLOW}●${RESET} ${WHITE}${BOLD}Google Sans${RESET}         ${GRAY}ttf-google-sans (via yay)${RESET}" "$CYAN"
        fi
    fi
    
    print_box_empty "$CYAN"
    print_box_end "$CYAN"
    echo ""
}

show_config_preview() {
    local folder="$1"
    
    print_box "📁 CONFIGURATIONS TO COPY" "$GREEN"
    print_box_empty "$GREEN"
    print_box_content "${CYAN}📂${RESET} ${WHITE}${BOLD}hypr/${RESET}                ${GRAY}→ ~/.config/hypr/${RESET}" "$GREEN"
    print_box_content "   ${DIM}├── hyprland.conf, hyprlock.conf, hypridle.conf${RESET}" "$GREEN"
    print_box_content "   ${DIM}└── CarmonyOS.py → .desktop file${RESET}" "$GREEN"
    print_box_empty "$GREEN"
    print_box_content "${CYAN}📂${RESET} ${WHITE}${BOLD}kitty/${RESET}               ${GRAY}→ ~/.config/kitty/${RESET}" "$GREEN"
    print_box_content "   ${DIM}└── kitty.conf${RESET}" "$GREEN"
    print_box_empty "$GREEN"
    print_box_content "${CYAN}📂${RESET} ${WHITE}${BOLD}waybar/${RESET}              ${GRAY}→ ~/.config/waybar/${RESET}" "$GREEN"
    print_box_content "   ${DIM}├── config.jsonc, style.css${RESET}" "$GREEN"
    print_box_content "   ${DIM}└── themes/ (CarmonyBar, NargatoBar, OmGlass)${RESET}" "$GREEN"
    
    if [[ "$folder" == "omarchy" ]]; then
        print_box_empty "$GREEN"
        print_box_content "${CYAN}📂${RESET} ${WHITE}${BOLD}walker/${RESET}              ${GRAY}→ ~/.config/walker/${RESET}" "$GREEN"
        print_box_empty "$GREEN"
        print_box_content "${YELLOW}📂${RESET} ${WHITE}${BOLD}themes/${RESET}              ${GRAY}→ ~/.local/share/omarchy/default/walker/${RESET}" "$GREEN"
        print_box_content "   ${DIM}└── omarchy-default/ (layout.xml, style.css)${RESET}" "$GREEN"
    fi
    
    print_box_empty "$GREEN"
    print_box_end "$GREEN"
    echo ""
}

ask_additional_packages() {
    local distro="$1"
    
    print_box "📦 ADDITIONAL PACKAGES" "$ORANGE"
    print_box_empty "$ORANGE"
    print_box_content "${WHITE}Would you like to install any additional packages?${RESET}" "$ORANGE"
    print_box_content "${DIM}Enter package names separated by spaces, or press Enter to skip${RESET}" "$ORANGE"
    print_box_empty "$ORANGE"
    print_box_content "${DIM}Examples: neovim git curl wget htop neofetch discord spotify${RESET}" "$ORANGE"
    print_box_empty "$ORANGE"
    print_box_end "$ORANGE"
    
    printf "\n  ${CYAN}${BOLD}    ➤ Additional packages: ${RESET}"
    read -r CUSTOM_PACKAGES
    
    if [[ -n "$CUSTOM_PACKAGES" ]]; then
        print_success "Will install: ${BOLD}$CUSTOM_PACKAGES${RESET}"
    else
        print_info "No additional packages selected"
    fi
}

ask_gui_dependencies() {
    echo ""
    print_box "🐍 PYTHON GUI SUPPORT" "$YELLOW"
    print_box_empty "$YELLOW"
    print_box_content "${WHITE}The ${BOLD}omarchy-control.py${RESET}${WHITE} script supports GUI features.${RESET}" "$YELLOW"
    print_box_content "${WHITE}Install Python GUI dependencies?${RESET}" "$YELLOW"
    print_box_empty "$YELLOW"
    print_box_content "${DIM}Packages: python-pip, tk, gtk4, gtk3, python-gobject${RESET}" "$YELLOW"
    print_box_empty "$YELLOW"
    print_box_end "$YELLOW"
    
    if confirm_action "Install Python GUI dependencies?" "y"; then
        INSTALL_GUI_DEPS=true
        print_success "GUI dependencies will be installed"
    else
        INSTALL_GUI_DEPS=false
        print_info "Skipping GUI dependencies"
    fi
}

backup_configs() {
    echo ""
    print_step "Creating backup directory..."
    print_info "Location: ${DIM}$BACKUP_DIR${RESET}"
    
    if ! mkdir -p "$BACKUP_DIR"; then
        print_error "Failed to create backup directory"
        return 1
    fi
    
    local configs_to_backup=("hypr" "waybar" "kitty" "walker" "themes" "rofi" "wofi")
    local backed_up=0
    
    echo ""
    for config in "${configs_to_backup[@]}"; do
        if [[ -d "$CONFIG_DIR/$config" ]]; then
            printf "  ${CYAN}  ⟳ ${RESET}${WHITE}Backing up ${BOLD}%s${RESET}${WHITE}...${RESET}" "$config"
            if cp -r "$CONFIG_DIR/$config" "$BACKUP_DIR/" 2>/dev/null; then
                printf "\r  ${GREEN}  ✔ ${RESET}${GREEN}Backed up ${BOLD}%s${RESET}                    \n" "$config"
                ((backed_up++))
            else
                printf "\r  ${RED}  ✖ ${RESET}${RED}Failed to backup ${BOLD}%s${RESET}              \n" "$config"
            fi
        else
            echo -e "  ${GRAY}  ○ ${RESET}${GRAY}Skipping ${BOLD}$config${RESET}${GRAY} (not found)${RESET}"
        fi
    done
    
    if [[ -d "$LOCAL_SHARE_DIR/omarchy" ]]; then
        printf "  ${CYAN}  ⟳ ${RESET}${WHITE}Backing up ${BOLD}omarchy themes${RESET}${WHITE}...${RESET}"
        if cp -r "$LOCAL_SHARE_DIR/omarchy" "$BACKUP_DIR/" 2>/dev/null; then
            printf "\r  ${GREEN}  ✔ ${RESET}${GREEN}Backed up ${BOLD}omarchy themes${RESET}            \n"
            ((backed_up++))
        fi
    fi
    
    echo ""
    if [[ $backed_up -eq 0 ]]; then
        print_info "No existing configs found to backup"
        rmdir "$BACKUP_DIR" 2>/dev/null || true
        BACKUP_DIR=""
    else
        print_success "Backup complete! ${BOLD}$backed_up${RESET}${GREEN} items saved${RESET}"
    fi
    
    log "Backup completed: $backed_up configs"
    return 0
}

install_fonts_arch() {
    echo ""
    print_step "Installing fonts..."
    
    print_font "Installing JetBrains Mono Nerd Font..."
    if sudo pacman -S --noconfirm --needed ttf-jetbrains-mono-nerd >> "$LOG_FILE" 2>&1; then
        print_success "JetBrains Mono Nerd Font installed"
    else
        print_warning "Failed to install JetBrains Mono Nerd Font from pacman"
    fi
    
    if check_yay; then
        print_font "Installing Google Sans Font (via yay)..."
        if yay -S --noconfirm ttf-google-sans >> "$LOG_FILE" 2>&1; then
            print_success "Google Sans Font installed"
        else
            print_warning "Failed to install Google Sans (AUR package)"
        fi
    else
        print_info "yay not found - skipping Google Sans (AUR package)"
        print_info "Install yay later and run: yay -S ttf-google-sans"
    fi
}

install_fonts_ubuntu() {
    echo ""
    print_step "Installing fonts..."
    
    print_font "Installing JetBrains Mono Nerd Font..."
    
    local font_dir="$HOME/.local/share/fonts/JetBrainsMono"
    mkdir -p "$font_dir"
    
    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || return
    
    print_info "Downloading from Nerd Fonts repository..."
    if wget -q --show-progress "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip" -O JetBrainsMono.zip 2>> "$LOG_FILE"; then
        print_info "Extracting fonts..."
        unzip -q JetBrainsMono.zip -d "$font_dir" >> "$LOG_FILE" 2>&1
        print_info "Updating font cache..."
        fc-cache -fv >> "$LOG_FILE" 2>&1
        print_success "JetBrains Mono Nerd Font installed"
    else
        print_warning "Failed to download JetBrains Mono Nerd Font"
    fi
    
    cd - > /dev/null || return
    rm -rf "$tmp_dir"
}

install_fonts_fedora() {
    echo ""
    print_step "Installing fonts..."
    
    print_font "Installing JetBrains Mono base font..."
    if sudo dnf install -y jetbrains-mono-fonts >> "$LOG_FILE" 2>&1; then
        print_success "JetBrains Mono base installed"
    fi
    
    print_font "Installing JetBrains Mono Nerd Font..."
    
    local font_dir="$HOME/.local/share/fonts/JetBrainsMono"
    mkdir -p "$font_dir"
    
    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || return
    
    print_info "Downloading from Nerd Fonts repository..."
    if wget -q --show-progress "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip" -O JetBrainsMono.zip 2>> "$LOG_FILE"; then
        print_info "Extracting fonts..."
        unzip -q JetBrainsMono.zip -d "$font_dir" >> "$LOG_FILE" 2>&1
        print_info "Updating font cache..."
        fc-cache -fv >> "$LOG_FILE" 2>&1
        print_success "JetBrains Mono Nerd Font installed"
    else
        print_warning "Failed to download Nerd Font variant"
    fi
    
    cd - > /dev/null || return
    rm -rf "$tmp_dir"
}

install_fonts_omarchy() {
    echo ""
    print_step "Installing fonts..."
    
    print_font "Installing JetBrains Mono Nerd Font..."
    if sudo pacman -S --noconfirm --needed ttf-jetbrains-mono-nerd >> "$LOG_FILE" 2>&1; then
        print_success "JetBrains Mono Nerd Font installed"
    fi
    
    if check_yay; then
        print_font "Installing Google Sans Font (via yay)..."
        if yay -S --noconfirm ttf-google-sans >> "$LOG_FILE" 2>&1; then
            print_success "Google Sans Font installed"
        else
            print_warning "Failed to install Google Sans"
        fi
    else
        print_info "yay not found - skipping Google Sans"
    fi
}

install_launcher() {
    local distro="$1"
    
    if [[ "$LAUNCHER_TYPE" == "skip" || -z "$LAUNCHER_TYPE" ]]; then
        return
    fi
    
    echo ""
    print_step "Installing ${BOLD}$LAUNCHER_TYPE${RESET} launcher..."
    
    case "$distro" in
        "Arch Linux")
            sudo pacman -S --noconfirm --needed "$LAUNCHER_TYPE" >> "$LOG_FILE" 2>&1
            ;;
        "Ubuntu")
            sudo apt install -y "$LAUNCHER_TYPE" >> "$LOG_FILE" 2>&1
            ;;
        "Fedora")
            sudo dnf install -y "$LAUNCHER_TYPE" >> "$LOG_FILE" 2>&1
            ;;
    esac
    
    if command -v "$LAUNCHER_TYPE" &>/dev/null; then
        print_success "$LAUNCHER_TYPE installed successfully"
    else
        print_warning "Failed to install $LAUNCHER_TYPE"
    fi
}

install_arch_packages() {
    echo ""
    print_box "📦 INSTALLING ARCH PACKAGES" "$CYAN"
    print_box_end "$CYAN"
    echo ""
    
    check_yay
    
    print_step "Updating system..."
    if sudo pacman -Syu --noconfirm >> "$LOG_FILE" 2>&1 & then
        fancy_spinner $! "Synchronizing package databases"
        wait $!
        print_success "System updated"
    else
        print_warning "System update had some issues, continuing..."
    fi
    
    local packages=(
        "hyprland"
        "hyprlock"
        "hypridle"
        "hyprsunset"
        "waybar"
        "jq"
        "imagemagick"
        "swww"
        "gtk4"
        "gtk3"
        "kitty"
        "thunar"
        "rofi"
        "btop"
        "mpv"
        "imv"
        "gnome-disk-utility"
        "unzip"
        "wget"
        "gvfs"
        "gvfs-mtp"
	"swayosd"
    )
    
    if [[ "$INSTALL_GUI_DEPS" == true ]]; then
        packages+=("python-pip" "tk" "python-gobject")
    fi
    
    if [[ -n "$CUSTOM_PACKAGES" ]]; then
        for pkg in $CUSTOM_PACKAGES; do
            packages+=("$pkg")
        done
    fi
    
    local total=${#packages[@]}
    local current=0
    local failed_packages=()
    
    echo ""
    print_step "Installing ${BOLD}$total${RESET} packages..."
    echo ""
    
    for package in "${packages[@]}"; do
        ((current++))
        progress_bar $current $total "$package"
        
        if ! sudo pacman -S --noconfirm --needed "$package" >> "$LOG_FILE" 2>&1; then
            failed_packages+=("$package")
        fi
        sleep 0.03
    done
    
    echo ""
    echo ""
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        print_warning "Some packages failed: ${failed_packages[*]}"
    fi
    
    install_fonts_arch
    install_launcher "Arch Linux"
    
    print_success "Package installation complete!"
    log "Arch packages installed"
}

install_ubuntu_packages() {
    echo ""
    print_box "📦 INSTALLING UBUNTU PACKAGES" "$ORANGE"
    print_box_end "$ORANGE"
    echo ""
    
    print_step "Updating package lists..."
    if sudo apt update >> "$LOG_FILE" 2>&1 & then
        fancy_spinner $! "Refreshing repositories"
        wait $!
        print_success "Package lists updated"
    fi
    
    print_step "Upgrading system..."
    if sudo apt upgrade -y >> "$LOG_FILE" 2>&1 & then
        fancy_spinner $! "Upgrading installed packages"
        wait $!
        print_success "System upgraded"
    fi
    
    print_step "Installing prerequisites..."
    sudo apt install -y software-properties-common wget unzip curl >> "$LOG_FILE" 2>&1 || true
    print_success "Prerequisites installed"
    
    print_step "Adding Hyprland repository..."
    sudo add-apt-repository -y ppa:hyprwm/hyprland >> "$LOG_FILE" 2>&1 || true
    sudo apt update >> "$LOG_FILE" 2>&1 || true
    print_success "Repository configured"
    
    local packages=(
        "hyprland"
        "hyprlock"
        "hypridle"
        "waybar"
        "jq"
        "imagemagick"
        "libgtk-4-1"
        "libgtk-3-0"
        "kitty"
        "nautilus"
        "rofi"
        "btop"
        "firefox"
        "obs-studio"
        "mpv"
        "imv"
        "gvfs"
        "gvfs-backends"
	"swayosd"
    )
    
    if [[ "$INSTALL_GUI_DEPS" == true ]]; then
        packages+=("python3-pip" "python3-tk" "python3-gi" "gir1.2-gtk-4.0" "gir1.2-gtk-3.0")
    fi
    
    if [[ -n "$CUSTOM_PACKAGES" ]]; then
        for pkg in $CUSTOM_PACKAGES; do
            packages+=("$pkg")
        done
    fi
    
    local total=${#packages[@]}
    local current=0
    
    echo ""
    print_step "Installing ${BOLD}$total${RESET} packages..."
    echo ""
    
    for package in "${packages[@]}"; do
        ((current++))
        progress_bar $current $total "$package"
        sudo apt install -y "$package" >> "$LOG_FILE" 2>&1 || true
        sleep 0.03
    done
    
    echo ""
    echo ""
    
    print_step "Installing swww from source..."
    if ! command -v cargo &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >> "$LOG_FILE" 2>&1 || true
        source "$HOME/.cargo/env" 2>/dev/null || true
    fi
    
    if command -v cargo &>/dev/null; then
        if cargo install swww >> "$LOG_FILE" 2>&1 & then
            fancy_spinner $! "Building swww (please wait)"
            wait $!
            print_success "swww installed"
        fi
        
        print_step "Installing hyprsunset..."
        if cargo install hyprsunset >> "$LOG_FILE" 2>&1 & then
            fancy_spinner $! "Building hyprsunset"
            wait $!
            print_success "hyprsunset installed"
        fi
    else
        print_warning "Cargo unavailable, skipping swww/hyprsunset"
    fi
    
    print_step "Installing Obsidian..."
    if wget -q "https://github.com/obsidianmd/obsidian-releases/releases/download/v1.5.3/obsidian_1.5.3_amd64.deb" -O /tmp/obsidian.deb >> "$LOG_FILE" 2>&1; then
        sudo dpkg -i /tmp/obsidian.deb >> "$LOG_FILE" 2>&1 || sudo apt install -f -y >> "$LOG_FILE" 2>&1
        rm -f /tmp/obsidian.deb
        print_success "Obsidian installed"
    else
        print_warning "Failed to download Obsidian"
    fi
    
    install_fonts_ubuntu
    install_launcher "Ubuntu"
    
    print_success "Package installation complete!"
    log "Ubuntu packages installed"
}

install_fedora_packages() {
    echo ""
    print_box "📦 INSTALLING FEDORA PACKAGES" "$BLUE"
    print_box_end "$BLUE"
    echo ""
    
    print_step "Updating system..."
    if sudo dnf upgrade -y >> "$LOG_FILE" 2>&1 & then
        fancy_spinner $! "Upgrading system packages"
        wait $!
        print_success "System updated"
    fi
    
    print_step "Installing prerequisites..."
    sudo dnf install -y wget unzip curl >> "$LOG_FILE" 2>&1 || true
    print_success "Prerequisites installed"
    
    print_step "Enabling RPM Fusion..."
    sudo dnf install -y \
        "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
        "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
        >> "$LOG_FILE" 2>&1 || true
    print_success "RPM Fusion enabled"
    
    local packages=(
        "hyprland"
        "hyprlock"
        "hypridle"
        "hyprsunset"
        "waybar"
        "jq"
	"rofi"
        "imagemagick"
        "swww"
        "gtk4"
        "gtk3"
        "kitty"
        "thunar"
        "btop"
        "firefox"
        "obs-studio"
        "obsidian"
        "mpv"
        "imv"
        "gvfs"
	"swayosd"
    )
    
    if [[ "$INSTALL_GUI_DEPS" == true ]]; then
        packages+=("python3-pip" "python3-tkinter" "python3-gobject" "gtk4-devel" "gtk3-devel")
    fi
    
    if [[ -n "$CUSTOM_PACKAGES" ]]; then
        for pkg in $CUSTOM_PACKAGES; do
            packages+=("$pkg")
        done
    fi
    
    local total=${#packages[@]}
    local current=0
    
    echo ""
    print_step "Installing ${BOLD}$total${RESET} packages..."
    echo ""
    
    for package in "${packages[@]}"; do
        ((current++))
        progress_bar $current $total "$package"
        sudo dnf install -y "$package" >> "$LOG_FILE" 2>&1 || true
        sleep 0.03
    done
    
    echo ""
    echo ""
    
    install_fonts_fedora
    install_launcher "Fedora"
    
    print_success "Package installation complete!"
    log "Fedora packages installed"
}

install_gui_python_deps() {
    if [[ "$INSTALL_GUI_DEPS" == true ]]; then
        echo ""
        print_step "Installing Python GUI packages via pip..."
        if pip3 install --user PyGObject >> "$LOG_FILE" 2>&1 & then
            fancy_spinner $! "Installing PyGObject"
            wait $!
            print_success "Python GUI dependencies installed"
        else
            print_warning "Some Python packages may have failed"
        fi
    fi
}

create_desktop_file() {
    local py_file="$CONFIG_DIR/hypr/CarmonyOS.py"
    local desktop_dir="$HOME/.local/share/applications"
    local desktop_file="$desktop_dir/carmonyos.desktop"
    
    echo ""
    print_step "Setting up Settings App..."
    
    if [[ -f "$py_file" ]]; then
        mkdir -p "$desktop_dir"
        
        chmod +x "$py_file"
        
        cat > "$desktop_file" << EOF
[Desktop Entry]
Name=Settings
Comment=CarmonyOS  Control Panel
Exec=python3 $py_file
Icon=preferences-system
Terminal=false
Type=Application
Categories=Settings;System;
Keywords=hyprland;control;settings;carmonyos;carmonyui;
StartupNotify=true
EOF
        
        print_success "Created: ${DIM}~/.local/share/applications/carmonyos.desktop${RESET}"
        print_success "CarmonyOS.py is now executable"
    else
        print_warning "omarchy-control.py not found in configs"
    fi
}

copy_configs() {
    local source_folder="$1"
    local source_path="$SCRIPT_DIR/$source_folder"
    
    echo ""
    print_box "📁 COPYING CONFIGURATIONS" "$GREEN"
    print_box_end "$GREEN"
    echo ""
    
    if [[ ! -d "$source_path" ]]; then
        print_error "Configuration folder not found!"
        print_error "Expected: ${DIM}$source_path${RESET}"
        print_info "Make sure the '${BOLD}$source_folder${RESET}' folder exists"
        log "ERROR: Config folder not found: $source_path"
        return 1
    fi
    
    mkdir -p "$CONFIG_DIR"
    
    local configs=()
    for dir in "$source_path"/*/; do
        if [[ -d "$dir" ]]; then
            local dirname=$(basename "$dir")
            if [[ "$dirname" != "themes" ]]; then
                configs+=("$dirname")
            fi
        fi
    done
    
    if [[ ${#configs[@]} -eq 0 ]]; then
        print_warning "No configuration folders found in $source_folder"
        return 1
    fi
    
    for config in "${configs[@]}"; do
        printf "  ${CYAN}  ⟳ ${RESET}${WHITE}Copying ${BOLD}%s${RESET}${WHITE}...${RESET}" "$config"
        
        if [[ -d "$CONFIG_DIR/$config" ]]; then
            rm -rf "$CONFIG_DIR/$config"
        fi
        
        if cp -r "$source_path/$config" "$CONFIG_DIR/"; then
            printf "\r  ${GREEN}  ✔ ${RESET}${GREEN}Copied ${BOLD}%s${RESET}${GREEN} → ~/.config/%s/${RESET}                \n" "$config" "$config"
        else
            printf "\r  ${RED}  ✖ ${RESET}${RED}Failed to copy ${BOLD}%s${RESET}                      \n" "$config"
        fi
        sleep 0.1
    done
    
    if [[ "$source_folder" == "omarchy" ]]; then
        echo ""
        print_step "Copying Omarchy themes..."
        
        local walker_theme_dest="$LOCAL_SHARE_DIR/omarchy/default/walker"
        mkdir -p "$walker_theme_dest"
        
        if [[ -d "$source_path/themes" ]]; then
            if cp -r "$source_path/themes/"* "$walker_theme_dest/" 2>/dev/null; then
                print_success "Themes copied to: ${DIM}~/.local/share/omarchy/default/walker/${RESET}"
            else
                print_warning "Failed to copy themes"
            fi
        else
            print_warning "themes folder not found in omarchy configs"
        fi
    fi
    
    echo ""
    print_success "All configurations copied successfully!"
    log "Configs copied from $source_folder"
    
    create_desktop_file
    
    return 0
}

ask_reboot() {
    echo ""
    print_box "🔄 SYSTEM REBOOT" "$YELLOW"
    print_box_empty "$YELLOW"
    print_box_content "${WHITE}A system reboot is ${BOLD}highly recommended${RESET}${WHITE} to apply all changes.${RESET}" "$YELLOW"
    print_box_content "${DIM}This ensures Hyprland, fonts, and all services start correctly.${RESET}" "$YELLOW"
    print_box_empty "$YELLOW"
    print_box_end "$YELLOW"
    
    if confirm_action "Would you like to reboot now?" "y"; then
        echo ""
        print_info "System will reboot in 5 seconds..."
        print_info "Press ${BOLD}Ctrl+C${RESET} to cancel"
        echo ""
        
        for i in 5 4 3 2 1; do
            printf "\r  ${YELLOW}${BOLD}  ⏱ ${RESET}${WHITE}Rebooting in ${BOLD}%d${RESET}${WHITE} seconds...${RESET}  " "$i"
            sleep 1
        done
        
        echo ""
        echo ""
        print_success "Rebooting now... See you on the other side! 🚀"
        sleep 1
        sudo reboot
    else
        echo ""
        print_info "Skipping reboot"
        print_warning "Remember to reboot later for all changes to take effect!"
    fi
}

show_completion() {
    local distro="$1"
    
    echo ""
    print_gradient_line
    echo ""
    
    echo -e "${GREEN}${BOLD}"
    print_centered "╔═══════════════════════════════════════════════════════════════════╗"
    print_centered "║                                                                   ║"
    print_centered "║               ✨ INSTALLATION COMPLETE! ✨                        ║"
    print_centered "║                                                                   ║"
    print_centered "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    
    echo ""
    print_box "📋 INSTALLATION SUMMARY" "$CYAN"
    print_box_empty "$CYAN"
    print_box_content "${WHITE}${BOLD}Distribution:${RESET}        ${GREEN}$distro${RESET}" "$CYAN"
    print_box_content "${WHITE}${BOLD}Config Location:${RESET}     ${GRAY}~/.config/${RESET}" "$CYAN"
    
    if [[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR" ]]; then
        print_box_content "${WHITE}${BOLD}Backup Location:${RESET}     ${GRAY}$BACKUP_DIR${RESET}" "$CYAN"
    fi
    
    print_box_content "${WHITE}${BOLD}Log File:${RESET}            ${GRAY}$LOG_FILE${RESET}" "$CYAN"
    
    if [[ "$INSTALL_GUI_DEPS" == true ]]; then
        print_box_content "${WHITE}${BOLD}Python GUI:${RESET}          ${GREEN}✔ Installed${RESET}" "$CYAN"
    fi
    
    if [[ -n "$LAUNCHER_TYPE" && "$LAUNCHER_TYPE" != "skip" ]]; then
        print_box_content "${WHITE}${BOLD}Launcher:${RESET}            ${GREEN}$LAUNCHER_TYPE${RESET}" "$CYAN"
    fi
    
    if [[ -n "$CUSTOM_PACKAGES" ]]; then
        print_box_content "${WHITE}${BOLD}Custom Packages:${RESET}     ${GRAY}$CUSTOM_PACKAGES${RESET}" "$CYAN"
    fi
    
    print_box_separator "$CYAN"
    print_box_content "${PINK}${BOLD}Fonts Installed:${RESET}" "$CYAN"
    print_box_content "  ${GRAY}• JetBrains Mono Nerd Font${RESET}" "$CYAN"
    if [[ "$distro" == "Arch Linux" || "$distro" == "Omarchy" ]] && [[ "$HAS_YAY" == true ]]; then
        print_box_content "  ${GRAY}• Google Sans (ttf-google-sans)${RESET}" "$CYAN"
    fi
    
    print_box_empty "$CYAN"
    print_box_end "$CYAN"
    
    echo ""
    print_box "🚀 GETTING STARTED" "$MAGENTA"
    print_box_empty "$MAGENTA"
    print_box_content "${WHITE}${BOLD}1.${RESET} ${GRAY}Reboot your system (highly recommended)${RESET}" "$MAGENTA"
    print_box_content "${WHITE}${BOLD}2.${RESET} ${GRAY}Select ${BOLD}Hyprland${RESET}${GRAY} from your display manager${RESET}" "$MAGENTA"
    print_box_content "${WHITE}${BOLD}3.${RESET} ${GRAY}Enjoy your beautiful new desktop! 🎉${RESET}" "$MAGENTA"
    print_box_empty "$MAGENTA"
    print_box_end "$MAGENTA"
    
    echo ""
    print_box "⌨️  KEYBOARD SHORTCUTS" "$BLUE"
    print_box_empty "$BLUE"
    print_box_content "${GOLD}${BOLD}  SUPER + Space${RESET}          ${GRAY}│${RESET}  ${WHITE}Open Application Launcher${RESET}" "$BLUE"
    print_box_content "${GOLD}${BOLD}  SUPER + Enter${RESET}              ${GRAY}│${RESET}  ${WHITE}Open Terminal (Kitty)${RESET}" "$BLUE"
    print_box_content "${GOLD}${BOLD}  SUPER + SHIFT + F${RESET}      ${GRAY}│${RESET}  ${WHITE}Open File Manager (Thunar)${RESET}" "$BLUE"
    print_box_content "${GOLD}${BOLD}  SUPER + F${RESET}              ${GRAY}│${RESET}  ${WHITE}Toggle Fullscreen${RESET}" "$BLUE"
    print_box_content "${GOLD}${BOLD}  SUPER + Q${RESET}              ${GRAY}│${RESET}  ${WHITE}Close Active Window${RESET}" "$BLUE"
    print_box_separator "$BLUE"
    print_box_content "${GOLD}${BOLD}  SUPER + L${RESET}              ${GRAY}│${RESET}  ${WHITE}Lock Screen${RESET}" "$BLUE"
    print_box_content "${GOLD}${BOLD}  SUPER + SHIFT + M${RESET}      ${GRAY}│${RESET}  ${WHITE}Exit Hyprland${RESET}" "$BLUE"
    print_box_content "${GOLD}${BOLD}  SUPER + ESC${RESET}      ${GRAY}│${RESET}  ${WHITE}Opens Logout Menu${RESET}" "$BLUE"
    print_box_empty "$BLUE"
    print_box_end "$BLUE"
    
    echo ""
    print_sparkle_line
    echo ""
    
    print_centered "Thank you for using CarmonyOS Config ${VERSION}!" "${BOLD}${MAGENTA}"
    print_centered "Made by ghvbb & locas for the Linux community" "${DIM}${WHITE}"
    
    echo ""
    
    ask_reboot
    
    echo ""
    printf "  ${DIM}Press any key to exit...${RESET}"
    read -n 1 -s -r
    echo ""
}

handle_distro() {
    local distro="$1"
    local config_folder="$2"
    local install_packages="$3"
    
    if [[ "$install_packages" == "true" ]]; then
        show_package_preview "$distro"
        show_config_preview "$config_folder"
        
        if ! confirm_action "Proceed with installation for ${BOLD}$distro${RESET}?" "y"; then
            print_warning "Installation cancelled by user"
            sleep 2
            return
        fi
        
        ask_launcher_type
        ask_additional_packages "$distro"
        ask_gui_dependencies
    else
        clear_screen
        print_mini_logo
        show_config_preview "$config_folder"
        
        if ! confirm_action "Proceed with configuration for ${BOLD}$distro${RESET}?" "y"; then
            print_warning "Configuration cancelled by user"
            sleep 2
            return
        fi
    fi
    
    clear_screen
    print_mini_logo
    
    print_box "🔧 SETTING UP ${distro^^}" "$MAGENTA"
    print_box_end "$MAGENTA"
    
    if confirm_action "Create a backup of existing configs?" "y"; then
        backup_configs
    else
        echo ""
        print_info "Skipping backup"
    fi
    
    if [[ "$install_packages" == "true" ]]; then
        case "$distro" in
            "Arch Linux")
                install_arch_packages
                ;;
            "Ubuntu")
                install_ubuntu_packages
                ;;
            "Fedora")
                install_fedora_packages
                ;;
        esac
        
        install_gui_python_deps
    else
        echo ""
        print_info "Skipping package installation (Omarchy mode)"
        print_success "All required packages are pre-installed! 💎"
        
        install_fonts_omarchy
    fi
    
    if ! copy_configs "$config_folder"; then
        print_error "Failed to copy configurations"
        echo ""
        printf "  ${DIM}Press any key to continue...${RESET}"
        read -n 1 -s -r
        return
    fi
    
    show_completion "$distro"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo ""
        echo -e "  ${RED}${BOLD}╔═══════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "  ${RED}${BOLD}║                                                                   ║${RESET}"
        echo -e "  ${RED}${BOLD}║   ⚠️  ERROR: Do not run this script as root!                       ║${RESET}"
        echo -e "  ${RED}${BOLD}║                                                                   ║${RESET}"
        echo -e "  ${RED}${BOLD}║   Run as a normal user with sudo privileges.                      ║${RESET}"
        echo -e "  ${RED}${BOLD}║   sudo will be used when needed.                                  ║${RESET}"
        echo -e "  ${RED}${BOLD}║                                                                   ║${RESET}"
        echo -e "  ${RED}${BOLD}╚═══════════════════════════════════════════════════════════════════╝${RESET}"
        echo ""
        exit 1
    fi
}

check_sudo() {
    if ! sudo -v 2>/dev/null; then
        echo ""
        print_error "This script requires sudo privileges"
        print_info "Please ensure you can run sudo commands"
        exit 1
    fi
}

check_internet() {
    print_step "Checking internet connection..."
    if ping -c 1 -W 3 google.com &>/dev/null || ping -c 1 -W 3 1.1.1.1 &>/dev/null; then
        print_success "Internet connection OK"
        return 0
    else
        print_warning "No internet connection detected"
        print_info "Some features may not work correctly"
        return 1
    fi
}

show_exit_message() {
    clear_screen
    echo ""
    echo ""
    print_gradient_line
    echo ""
    echo -e "${MAGENTA}${BOLD}"
    print_centered "╭─────────────────────────────────────────────────╮"
    print_centered "│                                                 │"
    print_centered "│      Thank you for using CarmonyOS! 💜          │"
    print_centered "│                                                 │"
    print_centered "│           See you next time! 👋                 │"
    print_centered "│                                                 │"
    print_centered "╰─────────────────────────────────────────────────╯"
    echo -e "${RESET}"
    echo ""
    print_gradient_line
    echo ""
    print_centered "OmGlass Manager v${VERSION}" "${DIM}${WHITE}"
    print_centered "${CODENAME}" "${DIM}${GRAY}"
    echo ""
    print_centered "github.com/ghvbb/OmGlass" "${DIM}${CYAN}"
    echo ""
    echo ""
}

show_about() {
    clear_screen
    print_logo
    
    print_box "ℹ️  ABOUT OMGLASS MANAGER" "$PURPLE"
    print_box_empty "$PURPLE"
    print_box_content "${WHITE}${BOLD}Version:${RESET}        ${CYAN}${VERSION}${RESET}" "$PURPLE"
    print_box_content "${WHITE}${BOLD}Codename:${RESET}       ${CYAN}${CODENAME}${RESET}" "$PURPLE"
    print_box_content "${WHITE}${BOLD}License:${RESET}        ${GRAY}MIT${RESET}" "$PURPLE"
    print_box_content "${WHITE}${BOLD}Author:${RESET}         ${GRAY}CarmonyOS${RESET}" "$PURPLE"
    print_box_empty "$PURPLE"
    print_box_separator "$PURPLE"
    print_box_empty "$PURPLE"
    print_box_content "${WHITE}CarmonyOS Manager is a beautiful installation script${RESET}" "$PURPLE"
    print_box_content "${WHITE}for setting up Hyprland with stunning configurations.${RESET}" "$PURPLE"
    print_box_empty "$PURPLE"
    print_box_content "${DIM}Supports: Arch Linux, Ubuntu, Fedora, Omarchy, Nobara,${RESET}" "$PURPLE"
    print_box_empty "$PURPLE"
    print_box_separator "$PURPLE"
    print_box_empty "$PURPLE"
    print_box_content "${WHITE}${BOLD}Features:${RESET}" "$PURPLE"
    print_box_content "${GREEN}  ✔${RESET} ${GRAY}Beautiful UI with colors and animations${RESET}" "$PURPLE"
    print_box_content "${GREEN}  ✔${RESET} ${GRAY}Automatic backup of existing configs${RESET}" "$PURPLE"
    print_box_content "${GREEN}  ✔${RESET} ${GRAY}Font installation (JetBrains Mono Nerd)${RESET}" "$PURPLE"
    print_box_content "${GREEN}  ✔${RESET} ${GRAY}Launcher selection (Rofi/Wofi/Walker)${RESET}" "$PURPLE"
    print_box_content "${GREEN}  ✔${RESET} ${GRAY}Custom package installation${RESET}" "$PURPLE"
    print_box_content "${GREEN}  ✔${RESET} ${GRAY}Detailed logging${RESET}" "$PURPLE"
    print_box_empty "$PURPLE"
    print_box_end "$PURPLE"
    
    echo ""
    printf "  ${DIM}Press any key to return...${RESET}"
    read -n 1 -s -r
}

cleanup() {
    tput cnorm 2>/dev/null || true
    echo ""
}

main() {
    trap cleanup EXIT INT TERM
    
    check_root
    check_sudo
    
    log "═══════════════════════════════════════════════════════════════"
    log "CarmonyOS ${VERSION} (${CODENAME}) started"
    log "Script directory: $SCRIPT_DIR"
    log "User: $(whoami)"
    log "Date: $(date)"
    log "═══════════════════════════════════════════════════════════════"
    
    while true; do
        show_main_menu
        read -r choice
        
        case "$choice" in
            1)
                handle_distro "Arch Linux" "arch" "true"
                ;;
            2)
                handle_distro "Ubuntu" "ubuntu" "true"
                ;;
            3)
                handle_distro "Fedora" "fedora" "true"
                ;;
            4)
                handle_distro "Omarchy" "omarchy" "false"
                ;;
            5)
                show_exit_message
                log "User exited normally"
                exit 0
                ;;
            "about"|"a"|"info")
                show_about
                ;;
            *)
                print_error "Invalid option. Please select 1-5"
                sleep 1
                ;;
        esac
    done
}

main "$@"
