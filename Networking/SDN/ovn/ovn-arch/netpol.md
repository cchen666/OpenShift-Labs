omc logs istio-ingressgateway-759f6d8f86-lv6ct -n istio-system | \
grep "HTTP" |
awk '{
    timestamp = $1;
    gsub(/^\[|Z]$/, "", timestamp); # Remove brackets and Z
    split(timestamp, parts, "T");
    split(parts[2], time_parts, ":");
    minute = parts[1] "T" time_parts[1] ":" time_parts[2];

    host = "";
    split($0, fields, "\"");
    if (length(fields) >= 8) { # Ensure enough fields exist
         host = fields[8]; # Adjust index based on your log
    }

    if (host != "") {
        print minute, host;
    }
}'