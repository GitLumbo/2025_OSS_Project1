#! /bin/bash
file_name="$0"
if [ $# -ne 1 ]; then
    echo "usage: $file_name file"
    exit 1
fi
csv_file_name="$1"
if [ ! -f "$csv_file_name" ]; then
    echo "[Error] $csv_file_name does not exist."
    exit 1
fi

# get_column_idx "컬럼명"
# => 해당 컬럼 index 출력
function get_column_idx() {
    local col_name="$1"
    cat "$csv_file_name" | head -n 1 | awk -F, -v col_name="$col_name" '{ 
        for (i = 1; i <= NF; i++) {
            if ($i == col_name) {
                print i
                exit
            }
        }
    }'
}

# get_value "찾는 행의 값" "그 값의 column" "출력할 column"
# => 해당 행의 해당 컬럼 값 출력
function get_value() {
    local source_value="$1"
    local source_col="$2"
    local target_col="$3"
    local source_idx=$(get_column_idx "$source_col")
    local target_idx=$(get_column_idx "$target_col")
    cat "$csv_file_name" | awk -F, -v target_idx="$target_idx" -v source_idx="$source_idx" -v source_value="$source_value" '$source_idx==source_value {print $target_idx}'
}

# search_player_data "선수 이름"
# => 해당 선수의 정보 출력
function search_player_data() {
    local player="$1"
    echo
    echo "Player stats for \"$player\""
    for col in "Player" "Team" "Age" "WAR" "HR" "BA"; do
        local value=$(get_value "$player" "Player" "$col")
        if [ -z "$value" ]; then
            echo "[Error] There is no player named \"$player\""
            break
        fi
        echo -n "$col: $value"
        if [ "$col" != "BA" ]; then
            echo -n ", "
        else
            echo
        fi
    done
}

# => SLG 상위 5명 선수 정보 출력(단, PA가 502 이상인 선수만)
function list_top5_slg() {
    echo
    echo "***Top 5 Players by SLG***"
    local slg_idx=$(get_column_idx "SLG")
    local pa_idx=$(get_column_idx "PA")
    local player_idx=$(get_column_idx "Player")
    local team_idx=$(get_column_idx "Team")
    local hr_idx=$(get_column_idx "HR")
    local rbi_idx=$(get_column_idx "RBI")

    cat $csv_file_name | sort -t, -k "$slg_idx" -nr | awk -F, -v pa_idx="$pa_idx" \
        -v p_i="$player_idx" \
        -v t_i="$team_idx" \
        -v s_i="$slg_idx" \
        -v h_i="$hr_idx" \
        -v r_i="$rbi_idx" \
        'NR > 1 && $pa_idx >= 502 {
            print count+1 ". " $p_i " (Team: " $t_i ") - SLG: " $s_i ", HR: " $h_i ", RBI: " $r_i;
            count++;
            if (count >= 5) exit 
        }'
}

# analyze_team_stats "팀 이름"
# => 해당 팀의 평균 나이, 홈런 합계, RBI합계 출력
function analyze_team_stats() {
    local team_name="$1"
    local team_idx=$(get_column_idx "Team")
    local age_idx=$(get_column_idx "Age")
    local hr_idx=$(get_column_idx "HR")
    local rbi_idx=$(get_column_idx "RBI")
    cat "$csv_file_name" | awk -F, -v t_n="$team_name" -v t_i="$team_idx" \
        -v a_i="$age_idx" \
        -v h_i="$hr_idx" \
        -v r_i="$rbi_idx" \
        '$t_i == t_n {
            sum_age+=$a_i;
            sum_hr+=$h_i;
            sum_rbi+=$r_i;
            count++
        } END {
            print "Average age: " sum_age / count;
            print "Total home runs: " sum_hr;
            print "Total RBI: " sum_rbi
        }'
}

# print_compare_top5 "필터링된 데이터"
# => SLG 상위 5명(단, PA가 502 이상인 선수만) layer name, team, age, SLG, batting average, and home run 순서대로 출력
function print_compare_top5() {
    local data="$1"
    local pa_idx=$(get_column_idx "PA")
    local slg_idx=$(get_column_idx "SLG")
    local player_idx=$(get_column_idx "Player")
    local team_idx=$(get_column_idx "Team")
    local hr_idx=$(get_column_idx "HR")
    local age_idx=$(get_column_idx "Age")
    local ba_idx=$(get_column_idx "BA")

    echo "$data" | sort -t, -k "$slg_idx" -nr | awk -F, -v pa_idx="$pa_idx" \
        -v p_i="$player_idx" \
        -v t_i="$team_idx" \
        -v s_i="$slg_idx" \
        -v h_i="$hr_idx" \
        -v a_i="$age_idx" \
        -v b_i="$ba_idx" \
        '$pa_idx >= 502 {
            print $p_i " (" $t_i ") - AGE: " $a_i ", SLG: " $s_i ", BA: " $b_i ", HR: " $h_i;
            count++;
            if (count >= 5) exit 
        }'
}

# compare_diff_age "group number"
# => 해당 그룹에 맞는 결과 출력
function compare_diff_age() {
    local group_idx="$1"
    local age_idx=$(get_column_idx "Age")
    echo
    if [ $group_idx -eq 1 ]; then
        echo "Top 5 by SLG in Group A (Age < 25):"
        local tmp=$(cat "$csv_file_name" | awk -F, -v age_idx="$age_idx" 'NR > 1 && $age_idx < 25 { print $0 }')
        print_compare_top5 "$tmp"
    elif [ $group_idx -eq 2 ]; then
        echo "Top 5 by SLG in Group B (Age 25-30):"
        local tmp=$(cat "$csv_file_name" | awk -F, -v age_idx="$age_idx" 'NR > 1 && $age_idx >= 25 && $age_idx <= 30 { print $0 }')
        print_compare_top5 "$tmp"
    elif [ $group_idx -eq 3 ]; then
        echo "Top 5 by SLG in Group C (Age > 30):"
        local tmp=$(cat "$csv_file_name" | awk -F, -v age_idx="$age_idx" 'NR > 1 && $age_idx > 30 { print $0 }')
        print_compare_top5 "$tmp"
    fi
}

# print_filter_top5 "필터링된 데이터"
# => home run으로 정렬 후, player name team hr ba rbi slg 순으로 출력
function print_filter_top5() {
    local data="$1"
    local pa_idx=$(get_column_idx "PA")
    local slg_idx=$(get_column_idx "SLG")
    local player_idx=$(get_column_idx "Player")
    local team_idx=$(get_column_idx "Team")
    local hr_idx=$(get_column_idx "HR")
    local rbi_idx=$(get_column_idx "RBI")
    local ba_idx=$(get_column_idx "BA")

    echo "$data" | sort -t, -k "$hr_idx,"$hr_idx"" -nr | awk -F, -v pa_idx="$pa_idx" \
        -v p_i="$player_idx" \
        -v t_i="$team_idx" \
        -v s_i="$slg_idx" \
        -v h_i="$hr_idx" \
        -v b_i="$ba_idx" \
        -v r_i="$rbi_idx" \
        '$pa_idx >= 502 {
            print $p_i " (" $t_i ") - HR: " $h_i ", BA: " $b_i ", RBI: " $r_i ", SLG: " $s_i;
        }'
}

# min_hr_ba "HR 하한" "BA 하한"
function min_hr_ba() {
    local min_hr="$1"
    local min_ba="$2"
    local hr_idx=$(get_column_idx "HR")
    local ba_idx=$(get_column_idx "BA")
    echo
    echo "Players with HR ≥ $min_hr and BA ≥ $min_ba:"
    local tmp=$(cat "$csv_file_name" | awk -F, -v hr_idx="$hr_idx" \
        -v ba_idx="$ba_idx" \
        -v min_hr="$min_hr" \
        -v min_ba="$min_ba" \
        'NR > 1 && $hr_idx >= min_hr && $ba_idx >= min_ba { print $0 }')
    print_filter_top5 "$tmp"
}

# print_report "필터링된 데이터"
function print_report() {
    local data="$1"
    local player_idx=$(get_column_idx "Player")
    local hr_idx=$(get_column_idx "HR")
    local rbi_idx=$(get_column_idx "RBI")
    local ba_idx=$(get_column_idx "BA")
    local obp_idx=$(get_column_idx "OBP")
    local ops_idx=$(get_column_idx "OPS")
    echo "$data" | sort -t, -k "$hr_idx,"$hr_idx"" -nr | awk -F, -v p_i="$player_idx" \
        -v h_i="$hr_idx" \
        -v r_i="$rbi_idx" \
        -v b_i="$ba_idx" \
        -v ob_i="$obp_idx" \
        -v op_i="$ops_idx" \
        '{
            print $p_i "\t" $h_i " " $r_i " " $b_i " " $ob_i " " $op_i;
            count++
        } END {
            print "-------------------------------------------------------";
            print "TEAM TOTALS: " count " players"
        }'
}

# team_report "팀 이름"
function team_report() {
    local team_name="$1"
    local team_idx=$(get_column_idx "Team")
    echo
    echo "================== $team_name PLAYER REPORT =================="
    echo "Date: $(date +%Y/%m/%d)"
    echo "-------------------------------------------------------"
    echo -e "PLAYER\t\tHR RBI AVG OBP OPS"
    echo "-------------------------------------------------------"
    local tmp=$(cat "$csv_file_name" | awk -F, -v team_idx="$team_idx" \
        -v team_name="$team_name" \
        '$team_idx==team_name {print $0}')
    print_report "$tmp"
}

echo "************* OSS1 - Project1 *************"
echo "*         StudentID : 12211564            *"
echo "*         Name      : 곽서현              *"
echo "*******************************************"

while :; do
    echo
    echo "[MENU]"
    echo "1. Search player stats by name in MLB data"
    echo "2. List top 5 players by SLG value"
    echo "3. Analyze the team stats - average age and total home runs"
    echo "4. Compare players in different age groups"
    echo "5. Search the players who meet specific statistical conditions"
    echo "6. Generate a performance report (formatted data)"
    echo "7. Quit"
    read -p "Enter your COMMAND (1~7): " user_input
    if [ "$user_input" -eq 7 ]; then
        echo "Have a good day!"
        break
    elif [ "$user_input" -eq 1 ]; then
        read -p "Enter a player name to search: " player
        search_player_data "$player"
    elif [ "$user_input" -eq 2 ]; then
        read -p "Do you want to see the top 5 players by SLG? (y/n): " response
        if [ "$response" == "y" ]; then
            list_top5_slg
        fi
    elif [ "$user_input" -eq 3 ]; then
        read -p "Enter team abbreviation (e.g., NYY, LAD, BOS): " response
        check=$(get_value "$response" "Team" "Team")
        if [ -z "$check" ]; then
            echo
            echo "[Error] Team \"$response\" does not exist."
        else
            echo
            echo "Team stats for $response"
            analyze_team_stats "$response"
        fi
    elif [ "$user_input" -eq 4 ]; then
        echo
        echo "Compare players by age groups:"
        echo "1. Group A (Age < 25)"
        echo "2. Group B (Age 25-30)"
        echo "3. Group C (Age > 30)"
        read -p "Select age group (1-3): " response
        compare_diff_age "$response"
    elif [ "$user_input" -eq 5 ]; then
        echo
        echo "Find players with specific criteria"
        read -p "Minimum home runs: " min_hr
        read -p "Minimum batting average (e.g., 0.280): " min_ba
        min_hr_ba "$min_hr" "$min_ba"
    elif [ "$user_input" -eq 6 ]; then
        echo "Generate a formatted player report for which team?"
        read -p "Enter team abbreviation (e.g., NYY, LAD, BOS): " response
        team_report "$response"
    fi
done
