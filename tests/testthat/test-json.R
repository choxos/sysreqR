test_that("internal JSON parser reads objects and arrays", {
  value <- json_read_text('{"Packages":{"R":{},"xml2":{}},"ok":true,"n":1}')

  expect_equal(names(value$Packages), c("R", "xml2"))
  expect_true(value$ok)
  expect_equal(value$n, 1)
})

test_that("internal JSON writer writes readable JSON", {
  tmp <- withr::local_tempfile(pattern = "sysreqr-json-", fileext = ".json")
  json_write(data.frame(package = "xml2", ok = TRUE), tmp)
  value <- json_read_file(tmp)

  expect_equal(value[[1]]$package, "xml2")
  expect_true(value[[1]]$ok)
})

test_that("JSON parser decodes unicode escapes", {
  value <- json_read_text('{"text":"caf\\u00e9"}')
  expect_equal(value$text, "café")
})

test_that("JSON parser handles nulls and nested arrays", {
  value <- json_read_text('{"a":null,"b":[1,2,3]}')
  expect_null(value$a)
  expect_equal(value$b, list(1, 2, 3))
})

test_that("JSON parser handles empty objects and empty arrays", {
  expect_equal(length(json_read_text("{}")), 0L)
  expect_equal(json_read_text("[]"), list())
  value <- json_read_text('{"a":{},"b":[]}')
  expect_equal(length(value$a), 0L)
  expect_equal(value$b, list())
})

test_that("JSON parser handles escaped backslashes and quotes in strings", {
  value <- json_read_text('{"path":"C:\\\\Users\\\\test","quote":"He said \\"hi\\""}')
  expect_equal(value$path, "C:\\Users\\test")
  expect_equal(value$quote, 'He said "hi"')
})

test_that("JSON parser handles scientific notation and negative numbers", {
  value <- json_read_text('{"big":1.5e3,"small":-2.5E-2,"int":-42}')
  expect_equal(value$big, 1500)
  expect_equal(value$small, -0.025)
  expect_equal(value$int, -42)
})

test_that("JSON parser rejects malformed input", {
  expect_error(json_read_text('{"a":}'))
  expect_error(json_read_text('{"a"'))
  expect_error(json_read_text("not json at all"))
})

test_that("JSON parser rejects unescaped control characters in strings", {
  raw_newline <- paste0('{"x":"a', "\n", 'b"}')
  expect_error(json_read_text(raw_newline), "control character")

  raw_tab <- paste0('{"x":"a', "\t", 'b"}')
  expect_error(json_read_text(raw_tab), "control character")
})

test_that("JSON parser still accepts escaped control characters", {
  value <- json_read_text('{"x":"a\\nb\\tc"}')
  expect_equal(value$x, "a\nb\tc")
})

test_that("JSON parser decodes surrogate pairs", {
  value <- json_read_text('{"emoji":"\\ud83d\\ude00"}')
  expect_equal(value$emoji, "\U0001F600")
})

test_that("JSON parser rejects invalid unicode escapes", {
  expect_error(json_read_text('{"x":"\\u00"}'), "unicode escape")
  expect_error(json_read_text('{"x":"\\uzz11"}'), "unicode escape")
  expect_error(json_read_text('{"x":"\\ud83d"}'), "surrogate")
  expect_error(json_read_text('{"x":"\\ude00"}'), "surrogate")
  expect_error(json_read_text('{"x":"\\ud83d\\u0041"}'), "surrogate")
})

test_that("JSON writer escapes control characters for a clean round-trip", {
  json_serialize <- getFromNamespace("json_serialize", "sysreqr")

  # Regression: \n, \r, and \t were double-escaped ("\\n"), so a serialized
  # newline parsed back as a literal backslash + n.
  whitespace <- json_serialize(list(x = "a\nb\tc\rd"))
  expect_equal(json_read_text(whitespace)$x, "a\nb\tc\rd")

  backslash <- json_serialize(list(x = "C:\\Users\\test"))
  expect_equal(json_read_text(backslash)$x, "C:\\Users\\test")

  backspace <- json_serialize(list(x = "a\bb\fc"))
  expect_equal(json_read_text(backspace)$x, "a\bb\fc")

  escape_char <- json_serialize(list(x = "a\033b"))
  expect_match(escape_char, "\\u001b", fixed = TRUE)
  expect_equal(json_read_text(escape_char)$x, "a\033b")
})
