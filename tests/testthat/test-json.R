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
