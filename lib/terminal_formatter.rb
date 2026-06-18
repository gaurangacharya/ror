# TerminalFormatter - Enhanced terminal output with colors and emojis
class TerminalFormatter
  # ANSI color codes
  COLORS = {
    reset: "\e[0m",
    bold: "\e[1m",
    dim: "\e[2m",
    italic: "\e[3m",
    underline: "\e[4m",
    blink: "\e[5m",
    reverse: "\e[7m",
    strikethrough: "\e[9m",
    
    # Text colors
    black: "\e[30m",
    red: "\e[31m",
    green: "\e[32m",
    yellow: "\e[33m",
    blue: "\e[34m",
    magenta: "\e[35m",
    cyan: "\e[36m",
    white: "\e[37m",
    bright_black: "\e[90m",
    bright_red: "\e[91m",
    bright_green: "\e[92m",
    bright_yellow: "\e[93m",
    bright_blue: "\e[94m",
    bright_magenta: "\e[95m",
    bright_cyan: "\e[96m",
    bright_white: "\e[97m",
    
    # Background colors
    bg_black: "\e[40m",
    bg_red: "\e[41m",
    bg_green: "\e[42m",
    bg_yellow: "\e[43m",
    bg_blue: "\e[44m",
    bg_magenta: "\e[45m",
    bg_cyan: "\e[46m",
    bg_white: "\e[47m",
    bg_bright_black: "\e[100m",
    bg_bright_red: "\e[101m",
    bg_bright_green: "\e[102m",
    bg_bright_yellow: "\e[103m",
    bg_bright_blue: "\e[104m",
    bg_bright_magenta: "\e[105m",
    bg_bright_cyan: "\e[106m",
    bg_bright_white: "\e[107m"
  }.freeze

  # Emojis for different states
  EMOJIS = {
    start: "🚀",
    success: "✅",
    error: "❌",
    warning: "⚠️",
    info: "ℹ️",
    processing: "🔄",
    completed: "🎉",
    failed: "💥",
    loading: "⏳",
    check: "✓",
    cross: "✗",
    star: "⭐",
    fire: "🔥",
    rocket: "🚀",
    gear: "⚙️",
    database: "🗄️",
    api: "🌐",
    file: "📄",
    folder: "📁",
    image: "🖼️",
    link: "🔗",
    lock: "🔒",
    unlock: "🔓",
    key: "🔑",
    search: "🔍",
    plus: "➕",
    minus: "➖",
    arrow_right: "➡️",
    arrow_left: "⬅️",
    arrow_up: "⬆️",
    arrow_down: "⬇️",
    refresh: "🔄",
    trash: "🗑️",
    edit: "✏️",
    save: "💾",
    download: "⬇️",
    upload: "⬆️",
    sync: "🔄",
    clock: "⏰",
    calendar: "📅",
    location: "📍",
    phone: "📞",
    email: "📧",
    web: "🌐",
    money: "💰",
    chart: "📊",
    graph: "📈",
    list: "📋",
    checkmark: "☑️",
    exclamation: "❗",
    question: "❓",
    lightbulb: "💡",
    heart: "❤️",
    thumbs_up: "👍",
    thumbs_down: "👎",
    party: "🎉",
    celebration: "🎊",
    trophy: "🏆",
    medal: "🏅",
    flag: "🏁",
    stop: "🛑",
    go: "🟢",
    pause: "⏸️",
    play: "▶️",
    stop_sign: "🛑",
    construction: "🚧",
    warning_sign: "⚠️",
    no_entry: "🚫",
    one_way: "↗️",
    recycle: "♻️",
    biohazard: "☢️",
    radioactive: "☢️",
    skull: "💀",
    crossbones: "☠️",
    peace: "☮️",
    yin_yang: "☯️",
    star_david: "✡️",
    cross_latin: "✝️",
    cross_orthodox: "☦️",
    star_crescent: "☪️",
    om: "🕉️",
    wheel_dharma: "☸️",
    menorah: "🕎",
    six_pointed_star: "🔯",
    aries: "♈",
    taurus: "♉",
    gemini: "♊",
    cancer: "♋",
    leo: "♌",
    virgo: "♍",
    libra: "♎",
    scorpio: "♏",
    sagittarius: "♐",
    capricorn: "♑",
    aquarius: "♒",
    pisces: "♓",
    ophiuchus: "⛎"
  }.freeze

  class << self
    def colorize(text, color = :white, style = :normal)
      return text unless color && COLORS[color]
      
      style_code = case style
      when :bold then COLORS[:bold]
      when :dim then COLORS[:dim]
      when :italic then COLORS[:italic]
      when :underline then COLORS[:underline]
      else ""
      end
      
      "#{style_code}#{COLORS[color]}#{text}#{COLORS[:reset]}"
    end

    def success(text)
      colorize("#{EMOJIS[:success]} #{text}", :bright_green, :bold)
    end

    def error(text)
      colorize("#{EMOJIS[:error]} #{text}", :bright_red, :bold)
    end

    def warning(text)
      colorize("#{EMOJIS[:warning]} #{text}", :bright_yellow, :bold)
    end

    def info(text)
      colorize("#{EMOJIS[:info]} #{text}", :bright_blue, :bold)
    end

    def processing(text)
      colorize("#{EMOJIS[:processing]} #{text}", :bright_cyan, :bold)
    end

    def completed(text)
      colorize("#{EMOJIS[:completed]} #{text}", :bright_green, :bold)
    end

    def failed(text)
      colorize("#{EMOJIS[:failed]} #{text}", :bright_red, :bold)
    end

    def header(text)
      colorize("#{EMOJIS[:star]} #{text}", :bright_magenta, :bold)
    end

    def subheader(text)
      colorize("#{EMOJIS[:arrow_right]} #{text}", :bright_cyan, :bold)
    end

    def step(text)
      colorize("#{EMOJIS[:gear]} #{text}", :bright_blue)
    end

    def data(text)
      colorize("#{EMOJIS[:database]} #{text}", :bright_white)
    end

    def api(text)
      colorize("#{EMOJIS[:api]} #{text}", :bright_blue)
    end

    def file(text)
      colorize("#{EMOJIS[:file]} #{text}", :bright_white)
    end

    def image(text)
      colorize("#{EMOJIS[:image]} #{text}", :bright_cyan)
    end

    def location(text)
      colorize("#{EMOJIS[:location]} #{text}", :bright_green)
    end

    def money(text)
      colorize("#{EMOJIS[:money]} #{text}", :bright_green)
    end

    def chart(text)
      colorize("#{EMOJIS[:chart]} #{text}", :bright_yellow)
    end

    def list(text)
      colorize("#{EMOJIS[:list]} #{text}", :bright_white)
    end

    def time(text)
      colorize("#{EMOJIS[:clock]} #{text}", :bright_blue)
    end

    def separator(char = "=", length = 60)
      colorize(char * length, :bright_black)
    end

    def progress(current, total, text = "")
      percentage = ((current.to_f / total) * 100).round(1)
      bar_length = 30
      filled_length = (bar_length * current / total).round
      bar = "█" * filled_length + "░" * (bar_length - filled_length)
      
      progress_text = "[#{current}/#{total}] #{bar} #{percentage}%"
      if text.present?
        progress_text += " #{text}"
      end
      
      colorize(progress_text, :bright_cyan)
    end

    def table_header(text)
      colorize(text, :bright_white, :bold)
    end

    def table_row(text)
      colorize(text, :white)
    end

    def highlight(text)
      colorize(text, :bright_yellow, :bold)
    end

    def dim(text)
      colorize(text, :bright_black)
    end

    def bright(text)
      colorize(text, :bright_white, :bold)
    end

    def print_line(text = "", color = :white, style = :normal)
      puts colorize(text, color, style)
    end

    def print_success(text)
      puts success(text)
    end

    def print_error(text)
      puts error(text)
    end

    def print_warning(text)
      puts warning(text)
    end

    def print_info(text)
      puts info(text)
    end

    def print_processing(text)
      puts processing(text)
    end

    def print_completed(text)
      puts completed(text)
    end

    def print_failed(text)
      puts failed(text)
    end

    def print_header(text)
      puts header(text)
    end

    def print_subheader(text)
      puts subheader(text)
    end

    def print_step(text)
      puts step(text)
    end

    def print_data(text)
      puts data(text)
    end

    def print_api(text)
      puts api(text)
    end

    def print_file(text)
      puts file(text)
    end

    def print_image(text)
      puts image(text)
    end

    def print_location(text)
      puts location(text)
    end

    def print_money(text)
      puts money(text)
    end

    def print_chart(text)
      puts chart(text)
    end

    def print_list(text)
      puts list(text)
    end

    def print_time(text)
      puts time(text)
    end

    def print_separator(char = "=", length = 60)
      puts separator(char, length)
    end

    def print_progress(current, total, text = "")
      puts progress(current, total, text)
    end

    def print_blank
      puts
    end

    def print_spacer
      puts separator("-", 40)
    end
  end
end
