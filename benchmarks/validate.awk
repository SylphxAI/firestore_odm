# Exactly one finite, nonnegative measurement per expected cell.
function number(value) {
  return value ~ /^[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$/ && \
    value + 0 <= 1.7976931348623157e308
}
function fail(message) {
  print project ": " message > "/dev/stderr"
  invalid = 1
}
BEGIN {
  split("cold full one", builds)
  for (i in builds) expected[builds[i]] = 1
  split("set get query update mapping", operations)
  for (i in operations) {
    expected[project SUBSEP operations[i]] = 1
    expected[raw SUBSEP operations[i]] = 1
  }
}
{
  if ($1 == "BENCH") {
    key = $2 SUBSEP $3
    if (NF != 4 || !number($4)) fail("malformed runtime row: " $0)
  } else {
    key = $1
    if (NF != 2 || !number($2)) fail("malformed build row: " $0)
  }
  if (!(key in expected)) fail("unexpected measurement: " $0)
  if (++seen[key] > 1) fail("duplicate measurement: " $0)
}
END {
  for (key in expected) {
    if (!(key in seen)) {
      label = key
      gsub(SUBSEP, " ", label)
      fail("missing measurement: " label)
    }
  }
  exit invalid ? 1 : 0
}
