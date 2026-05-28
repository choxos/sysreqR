# Generate the package hex sticker from the source icon.

if (!requireNamespace("hexSticker", quietly = TRUE)) {
  stop(
    "The hexSticker package is required to regenerate the sticker.",
    " Install it with install.packages(\"hexSticker\").",
    call. = FALSE
  )
}

source_icon <- file.path("data-raw", "sysreqR_icon.png")
logo <- file.path("man", "figures", "logo.png")

dir.create(dirname(logo), showWarnings = FALSE, recursive = TRUE)

hexSticker::sticker(
  subplot = source_icon,
  package = "sysreqR",
  filename = logo,
  s_x = 1.0,
  s_y = 1.05,
  s_width = 0.56,
  s_height = 0.56,
  p_x = 1.0,
  p_y = 0.36,
  p_color = "#14212B",
  p_family = "sans",
  p_fontface = "bold",
  p_size = 16,
  h_fill = "#F8FBFD",
  h_color = "#447099",
  h_size = 1.35,
  white_around_sticker = FALSE,
  dpi = 320
)
