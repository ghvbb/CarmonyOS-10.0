// THIS IS NEXFETCH BY GHVBB ON 2026 !

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sys/utsname.h>
#include <sys/sysinfo.h>
#include <sys/stat.h>
#include <pwd.h>
#include <unistd.h>
#include <chrono>
#include <algorithm>
#include <cstring>
#include <climits>
#include <dirent.h>

using std::string;
using std::vector;
using std::ifstream;
using std::cout;

namespace C {
    const char* R  = "\033[0m";
    const char* B  = "\033[1m";
    const char* D  = "\033[2m";
    const char* BB = "\033[1;34m";
    const char* BC = "\033[1;36m";
    const char* BG = "\033[1;32m";
    const char* BY = "\033[1;33m";
    const char* BM = "\033[1;35m";
    const char* BR = "\033[1;31m";
    const char* BW = "\033[1;37m";
}

struct Config {
    bool username  = true;
    bool hostname  = true;
    bool os        = true;
    bool kernel    = true;
    bool uptime    = true;
    bool packages  = true;
    bool memory    = true;
    bool cpu       = true;
    bool age       = true;
    bool separator = true;
    bool colors    = true;
    string logo_color = "blue";
};

string getHomePath() {
    const char *h = getenv("HOME");
    if (h) return string(h);
    struct passwd *pw = getpwuid(getuid());
    if (pw) return string(pw->pw_dir);
    return "/tmp";
}

string getUsername() {
    struct passwd *pw = getpwuid(getuid());
    if (!pw) return "unknown";
    return string(pw->pw_name);
}

string getHostname() {
    char buf[HOST_NAME_MAX + 1];
    if (gethostname(buf, sizeof(buf)) == 0) {
        buf[HOST_NAME_MAX] = '\0';
        return string(buf);
    }
    return "localhost";
}

string getOSName() {
    ifstream file("/etc/os-release");
    string line;
    while (std::getline(file, line)) {
        if (line.compare(0, 13, "PRETTY_NAME=\"") == 0)
            return line.substr(13, line.length() - 14);
    }
    return "Linux";
}

string getArch() {
    struct utsname buf;
    if (uname(&buf) == 0) return string(buf.machine);
    return "";
}

string getKernel() {
    struct utsname buf;
    if (uname(&buf) != 0) return "unknown";
    return string(buf.release);
}

string getUptime() {
    struct sysinfo si;
    if (sysinfo(&si) != 0) return "unknown";
    long total = si.uptime;
    int days  = total / 86400;
    int hours = (total % 86400) / 3600;
    int mins  = (total % 3600) / 60;
    string r;
    if (days > 0) {
        r += std::to_string(days);
        r += (days == 1) ? " day" : " days";
    }
    if (hours > 0) {
        if (!r.empty()) r += ", ";
        r += std::to_string(hours);
        r += (hours == 1) ? " hour" : " hours";
    }
    if (mins > 0 || r.empty()) {
        if (!r.empty()) r += ", ";
        r += std::to_string(mins);
        r += (mins == 1) ? " min" : " mins";
    }
    return r;
}

static int countFilesWithExt(const string& path, const string& ext) {
    DIR *dir = opendir(path.c_str());
    if (!dir) return 0;
    int count = 0;
    struct dirent *entry;
    while ((entry = readdir(dir))) {
        string n(entry->d_name);
        if (n.length() > ext.length() && n.substr(n.length() - ext.length()) == ext)
            count++;
    }
    closedir(dir);
    return count;
}

static int countDirEntries(const string& path) {
    DIR *dir = opendir(path.c_str());
    if (!dir) return 0;
    int count = 0;
    struct dirent *entry;
    while ((entry = readdir(dir))) {
        if (entry->d_name[0] != '.') count++;
    }
    closedir(dir);
    return count;
}

string getPackages() {
    vector<std::pair<string, int>> mgr;
    int dpkg = countFilesWithExt("/var/lib/dpkg/info", ".list");
    if (dpkg > 0) mgr.push_back({"dpkg", dpkg});
    int pacman = countDirEntries("/var/lib/pacman/local");
    if (pacman > 0) mgr.push_back({"pacman", pacman});
    struct stat st;
    if (stat("/var/lib/rpm/Packages", &st) == 0 || stat("/var/lib/rpm/Packages.db", &st) == 0) {
        FILE *fp = popen("rpm -qa 2>/dev/null | wc -l", "r");
        if (fp) {
            char buf[64];
            if (fgets(buf, sizeof(buf), fp)) {
                int c = atoi(buf);
                if (c > 0) mgr.push_back({"rpm", c});
            }
            pclose(fp);
        }
    }
    int flatpak = countDirEntries("/var/lib/flatpak/app");
    if (flatpak > 0) mgr.push_back({"flatpak", flatpak});
    int snap = countDirEntries("/snap");
    if (snap > 2) mgr.push_back({"snap", snap - 2});
    if (mgr.empty()) return "0";
    int total = 0;
    for (auto& m : mgr) total += m.second;
    string r = std::to_string(total) + " (";
    for (size_t i = 0; i < mgr.size(); i++) {
        if (i > 0) r += ", ";
        r += std::to_string(mgr[i].second) + " " + mgr[i].first;
    }
    r += ")";
    return r;
}

string getMemory() {
    ifstream file("/proc/meminfo");
    if (!file.is_open()) return "unknown";
    long total_kb = 0, avail_kb = 0, free_kb = 0, buf_kb = 0, cache_kb = 0;
    string line;
    while (std::getline(file, line)) {
        if (line.compare(0, 9, "MemTotal:")       == 0) total_kb = atol(line.c_str() + 9);
        else if (line.compare(0, 13, "MemAvailable:") == 0) avail_kb = atol(line.c_str() + 13);
        else if (line.compare(0, 8, "MemFree:")    == 0) free_kb = atol(line.c_str() + 8);
        else if (line.compare(0, 8, "Buffers:")    == 0) buf_kb = atol(line.c_str() + 8);
        else if (line.compare(0, 7, "Cached:")     == 0) cache_kb = atol(line.c_str() + 7);
    }
    long used_kb = (avail_kb > 0) ? total_kb - avail_kb : total_kb - free_kb - buf_kb - cache_kb;
    long used_mb  = used_kb / 1024;
    long total_mb = total_kb / 1024;
    int pct = (total_kb > 0) ? (int)((used_kb * 100) / total_kb) : 0;
    return std::to_string(used_mb) + " / " + std::to_string(total_mb) + " MiB (" +
           std::to_string(pct) + "%)";
}

string getCPU() {
    ifstream file("/proc/cpuinfo");
    if (!file.is_open()) return "unknown";
    string line, model;
    int cores = 0;
    while (std::getline(file, line)) {
        if (line.compare(0, 10, "model name") == 0) {
            size_t c = line.find(':');
            if (c != string::npos) model = line.substr(c + 2);
        }
        if (line.compare(0, 9, "processor") == 0) cores++;
    }
    if (model.empty()) return "unknown";
    size_t p;
    while ((p = model.find("  ")) != string::npos) model.erase(p, 1);
    string rm[] = {"(R)", "(TM)", "(tm)", "CPU ", "Processor"};
    for (auto& s : rm)
        while ((p = model.find(s)) != string::npos) model.erase(p, s.length());
    while (!model.empty() && model.front() == ' ') model.erase(0, 1);
    while (!model.empty() && model.back()  == ' ') model.pop_back();
    if (cores > 0) model += " (" + std::to_string(cores) + ")";
    return model;
}

string getOSAge() {
    struct stat st;
    vector<string> paths = {"/var/log/installer/syslog", "/var/log/anaconda/anaconda.log", "/"};
    for (auto& p : paths) {
        if (stat(p.c_str(), &st) == 0 && st.st_ctime > 0) {
            auto now = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
            long diff = now - st.st_ctime;
            if (diff < 0) continue;
            int days = diff / 86400;
            if (days > 365) {
                int y = days / 365, d = days % 365;
                return std::to_string(y) + (y == 1 ? " year" : " years") +
                       ", " + std::to_string(d) + (d == 1 ? " day" : " days");
            }
            return std::to_string(days) + (days == 1 ? " day" : " days");
        }
    }
    return "unknown";
}

Config loadConfig(const string& path) {
    Config cfg;
    ifstream file(path);
    if (!file.is_open()) return cfg;
    string content((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
    auto check = [&](const string& f) -> int {
        size_t p = content.find("\"" + f + "\"");
        if (p == string::npos) return -1;
        size_t c = content.find(':', p);
        if (c == string::npos) return -1;
        string rest = content.substr(c + 1, 20);
        if (rest.find("false") != string::npos) return 0;
        if (rest.find("true")  != string::npos) return 1;
        return -1;
    };
    int v;
    if ((v = check("username"))  != -1) cfg.username  = v;
    if ((v = check("hostname"))  != -1) cfg.hostname  = v;
    if ((v = check("os"))        != -1) cfg.os        = v;
    if ((v = check("kernel"))    != -1) cfg.kernel    = v;
    if ((v = check("uptime"))    != -1) cfg.uptime    = v;
    if ((v = check("packages"))  != -1) cfg.packages  = v;
    if ((v = check("memory"))    != -1) cfg.memory    = v;
    if ((v = check("cpu"))       != -1) cfg.cpu       = v;
    if ((v = check("age"))       != -1) cfg.age       = v;
    if ((v = check("separator")) != -1) cfg.separator = v;
    if ((v = check("colors"))    != -1) cfg.colors    = v;
    size_t lp = content.find("\"logo_color\"");
    if (lp != string::npos) {
        size_t q1 = content.find('"', content.find(':', lp) + 1);
        size_t q2 = content.find('"', q1 + 1);
        if (q1 != string::npos && q2 != string::npos)
            cfg.logo_color = content.substr(q1 + 1, q2 - q1 - 1);
    }
    return cfg;
}

const char* getLogoColor(const string& n) {
    if (n == "red")     return C::BR;
    if (n == "green")   return C::BG;
    if (n == "yellow")  return C::BY;
    if (n == "magenta") return C::BM;
    if (n == "cyan")    return C::BC;
    if (n == "white")   return C::BW;
    return C::BB;
}

size_t displayWidth(const string& s) {
    size_t w = 0;
    bool esc = false;
    for (size_t i = 0; i < s.size(); i++) {
        unsigned char c = s[i];
        if (c == '\033') { esc = true; continue; }
        if (esc) { if (c == 'm') esc = false; continue; }
        if (c < 0x80)             { w++; }
        else if ((c & 0xE0) == 0xC0) { w++; i += 1; }
        else if ((c & 0xF0) == 0xE0) { w++; i += 2; }
        else if ((c & 0xF8) == 0xF0) { w += 2; i += 3; }
    }
    return w;
}

void createDefaultConfig(const string& dir) {
    string cmd = "mkdir -p " + dir;
    system(cmd.c_str());
    string p = dir + "config.jsonc";
    struct stat st;
    if (stat(p.c_str(), &st) == 0) return;
    std::ofstream out(p);
    if (!out.is_open()) return;
    out << "{\n"
        << "    \"username\": true,\n"
        << "    \"hostname\": true,\n"
        << "    \"os\": true,\n"
        << "    \"kernel\": true,\n"
        << "    \"uptime\": true,\n"
        << "    \"packages\": true,\n"
        << "    \"memory\": true,\n"
        << "    \"cpu\": true,\n"
        << "    \"age\": true,\n"
        << "    \"separator\": true,\n"
        << "    \"colors\": true,\n"
        << "    \"logo_color\": \"blue\"\n"
        << "}\n";
    out.close();
}

int main() {
    string configDir = getHomePath() + "/.config/nexfetch/";
    createDefaultConfig(configDir);
    Config cfg = loadConfig(configDir + "config.jsonc");
    const char* lc = getLogoColor(cfg.logo_color);

    string user = getUsername();
    string host = getHostname();

    vector<string> lines;

    if (cfg.username || cfg.hostname) {
        lines.push_back(string(C::BB) + user + C::R + C::D + "@" + C::R + C::BC + host + C::R);
    }

    if (cfg.separator) {
        size_t slen = user.length() + 1 + host.length();
        string sep;
        for (size_t i = 0; i < slen; i++) sep += "─";
        lines.push_back(string(C::D) + sep + C::R);
    }

    struct Field { const char* ic; const char* icon; const char* label; string val; };
    vector<Field> fields;

    if (cfg.os) {
        string os = getOSName();
        string arch = getArch();
        if (!arch.empty()) os += " " + arch;
        fields.push_back({C::BB, "󰣇", "OS      ", os});
    }
    if (cfg.kernel)   fields.push_back({C::BG, "󰒋", "Kernel  ", getKernel()});
    if (cfg.uptime)   fields.push_back({C::BY, "󰅐", "Uptime  ", getUptime()});
    if (cfg.packages) fields.push_back({C::BM, "󰏖", "Packages", getPackages()});
    if (cfg.cpu)      fields.push_back({C::BR, "󰍛", "CPU     ", getCPU()});
    if (cfg.memory)   fields.push_back({C::BY, "󰍜", "Memory  ", getMemory()});
    if (cfg.age)      fields.push_back({C::BM, "󰃮", "Age     ", getOSAge()});

    for (auto& f : fields) {
        string line;
        line += f.ic;
        line += " ";
        line += f.icon;
        line += " ";
        line += C::R;
        line += C::B;
        line += f.label;
        line += C::R;
        line += C::D;
        line += " │ ";
        line += C::R;
        line += f.val;
        lines.push_back(line);
    }

    if (cfg.colors) {
        lines.push_back("");
        string row1 = "   ";
        for (int i = 0; i < 8; i++)
            row1 += "\033[4" + std::to_string(i) + "m   " + string(C::R);
        lines.push_back(row1);
        string row2 = "   ";
        for (int i = 0; i < 8; i++)
            row2 += "\033[10" + std::to_string(i) + "m   " + string(C::R);
        lines.push_back(row2);
    }

    vector<string> logo;
    ifstream logoFile(configDir + "logo.txt");
    string tmp;

    if (logoFile.is_open()) {
        while (std::getline(logoFile, tmp)) logo.push_back(tmp);
    } else {
        logo = {
            "     ╱▔▔▔▔▔▔▔╲     ",
            "    ╱         ╲    ",
            "   ╱    ╱▔▔╲    ╲   ",
            "  ╱    ╱    ╲    ╲  ",
            " ╱    ╱      ╲    ╲ ",
            "╱____╱   NEX  ╲____╲",
            " ╲    ╲      ╱    ╱ ",
            "  ╲    ╲    ╱    ╱  ",
            "   ╲    ╲__╱    ╱   ",
            "    ╲         ╱    ",
            "     ╲_______╱     ",
        };
    }

    size_t logoW = 0;
    for (auto& l : logo) {
        size_t w = displayWidth(l);
        if (w > logoW) logoW = w;
    }

    size_t gap = 3;
    size_t totalLogoCol = logoW + gap;
    size_t maxRows = std::max(logo.size(), lines.size());

    size_t logoOffset = 0, infoOffset = 0;
    if (logo.size() < lines.size()) logoOffset = (lines.size() - logo.size()) / 2;
    else if (lines.size() < logo.size()) infoOffset = (logo.size() - lines.size()) / 2;

    cout << "\n";

    for (size_t i = 0; i < maxRows; i++) {
        cout << "  ";

        if (i >= logoOffset && (i - logoOffset) < logo.size()) {
            string& l = logo[i - logoOffset];
            size_t w = displayWidth(l);
            cout << lc << l << C::R;
            for (size_t p = w; p < totalLogoCol; p++) cout << ' ';
        } else {
            for (size_t p = 0; p < totalLogoCol; p++) cout << ' ';
        }

        if (i >= infoOffset && (i - infoOffset) < lines.size()) {
            cout << lines[i - infoOffset];
        }

        cout << "\n";
    }

    cout << "\n";
    re
