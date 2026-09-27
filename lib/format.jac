cl def:pub money(amount: float) -> str {
    text = f"{amount:.0f}";
    whole = text;
    sign = "";
    if whole.startswith("-") { sign = "-"; whole = whole[1:]; }
    groups: list[str] = [];
    while len(whole) > 3 {
        groups = [whole[len(whole) - 3:]] + groups;
        whole = whole[:len(whole) - 3];
    }
    return sign + "$" + ",".join([whole] + groups);
}

cl def:pub hour_label(hour: float) -> str {
    h = int(hour);
    m = int((hour - h) * 60);
    suffix = "AM" if h < 12 else "PM";
    h12 = h % 12;
    if h12 == 0 { h12 = 12; }
    mm = str(m) if m >= 10 else "0" + str(m);
    return str(h12) + ":" + mm + " " + suffix;
}
