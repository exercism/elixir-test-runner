#!/usr/bin/awk -f

# Strip all whitespace from the left-side of a string
function left_strip (string) {
  sub(/^\s+/, "", string);
  return string;
}

# Escape all double quotes in a string
function escape_double_quote (string) {
  gsub(/"/, "\"\"", string);
  return string;
}

BEGIN {
  # Initialize counters
  test_count=0;
  describe_block_count=0;
  test_block_count=0;

  # Initialize flags
  in_describe=0;
  in_test=0;
}

# Skip blank lines
($0 ~ /^\s*$/) { next; }

# Handle the end of a do..end block
($0 ~ "end" && in_test) {
  test_block_count-=1;
  if (test_block_count == 0) {
    in_test=0;
    test_count+=1;
    in_assert=0;
    assert_count=0;
  }
}

# Handle an assert expression
($0 ~ "assert" && in_test) {
  in_assert=1;
  assert_count+=1;
  meta[test_count]["assert_count"]=assert_count+1;
  meta[test_count]["assertions"][assert_count]="";
}

# Handle test block lines of code outside of assert expression
(in_test && !in_assert) {
  stripped=left_strip($0);
  escaped=escape_double_quote(stripped)

  if (meta[test_count]["code"] == "") {
    meta[test_count]["code"]=escaped;
  } else {
    meta[test_count]["code"]=meta[test_count]["code"] "\n" escaped;
  }
}

# Handle test block lines of code inside of an assert expression
(in_test && in_assert) {
  stripped=left_strip($0);
  escaped=escape_double_quote(stripped)

  if (meta[test_count]["assertions"][assert_count] == "") {
    meta[test_count]["assertions"][assert_count]=escaped;
  } else {
    meta[test_count]["assertions"][assert_count]=meta[test_count]["assertions"][assert_count] "\n" escaped;
  }
}

# Handle opening test function block
#
# When parsing the test function name, the field separator (FS) is changes to a
# double-quote so that we can easily get the string that describes the test
# case. This string matches the key used in the test-runner output.
($0 ~ "test") {
  in_test=1;
  assert_count=-1;
  FS="\"";
  $0=$0;
  current_test=$2;
  meta[test_count]["name"]=current_test;
  meta[test_count]["code"]="";
  meta[test_count]["assert_count"]=assert_count;
  FS=" ";
}

# handle the do of do..end block
($0 ~ " do" && in_test) {
  test_block_count+=1;
}

# handle the opening do of describe function
($0 ~ " do" && in_describe) {
  describe_block_count+=1;
}

# Print the accrued results to stdout
#
# The output record separate (ORS) is changed to "," so that each print stays on
# the same line to make it more readable.  Before the last assertion is printed
# the ORS is changed back to "\n" so that the next record appears on the next line.
END {
  for (i=0; i < test_count; i+=1) {
    ORS=",";
    print "\"" meta[i]["name"] "\"";
    print "\"" meta[i]["code"] "\"";
    print meta[i]["assert_count"];

    for (j=0; j < meta[i]["assert_count"] - 1 ; j+=1) {
      print "\"" meta[i]["assertions"][j] "\"";
    }
    ORS="\n";
    print "\"" meta[i]["assertions"][meta[i]["assert_count"] - 1] "\"";
  }
}
