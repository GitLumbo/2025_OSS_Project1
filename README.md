# 2025 OSS Project1(CSE2113)

202501-CSE2113-001 오픈소스SW개론 강의에서 수행된 프로젝트입니다.

이 스크립트는 **Bash Shell**을 사용하여 `.csv` 형식의 MLB 선수 데이터를 분석하고 리포트 형태로 출력하는 프로그램입니다.

## 💻 개발환경

GNU bash, version 5.2.21(1)-release (x86_64-pc-linux-gnu)

## 📓 코드 설명

프로그램 접속시 아래 7가지의 메뉴로 구성됩니다.

```markdown
1. Search player stats by name in MLB data
2. List top 5 players by SLG value
3. Analyze the team stats - average age and total home runs
4. Compare players in different age groups
5. Search the players who meet specific statistical conditions
6. Generate a performance report (formatted data)
7. Quit
```

### 1. Search player stats by name in MLB data

**⚙️ 기능**: `사용자가 입력하는 선수`의 `이름, 팀, 나이, WAR, 홈런, 타율`을 출력

**🛠 구현**: **awk**를 이용하여 해당 선수의 이름과 매칭하는 열에서 정보들을 추출하여 출력하도록 구현함

### 2. List top 5 players by SLG value

**⚙️ 기능**: 타석수가 502 이상인 선수들 중에서 장타율이 높은 선수 상위 5명 순서대로 `이름, 팀, WAR, 홈런, 타점`을 출력

**🛠 구현**: `sort -t, -k "$slg_idx" -nr`를 이용하여 장타율 순서대로 정렬 후, **awk**를 이용하여 타석수가 502 이상인 선수 중 상위 5명만 출력하도록 구현함

### 3. Analyze the team stats - average age and total home runs

**⚙️ 기능**: `사용자가 입력하는 팀`의 `평균 나이, 홈런 합계, 타점 합계`를 출력(_사용자가 입력한 팀이 존재하지 않는 경우, 에러메세지 출력_)

**🛠 구현**: **awk**를 이용하여 해당 팀과 매칭되는 열에 대해서 변수를 이용하여 계산을 하고, END를 이용하여 마지막에 통계 정보 출력하도록 구현함

### 4. Compare players in different age groups

**⚙️ 기능**: 타석수가 502이상인 선수들 중 25세 미만 그룹, 25-39세 그룹, 30세 초과 그룹 중에서 `사용자가 선택한 그룹`의 `선수 이름, 팀 이름, 나이, 장타율, 타율, 홈런`을 장타율에 대해 내림차순으로 출력

**🛠 구현**: 아래의 3가지 단계로 구현함

```markdown
1. **awk**를 이용하여 사용자가 선택한 나이 그룹에 맞게 필터링
2. `sort -t, -k "$slg_idx" -nr` 를 이용하여 장타율 기준으로 내림차순 정렬
3. **awk**를 이용하여 타석수가 502이상인 선수에 대하여 상위 5명만 출력
```

### 5. Search the players who meet specific statistical conditions

**⚙️ 기능**: 사용자가 입력한 `홈런 하한`, `타율 하한` 이상이고 타석수가 502이상인 선수들을 홈런에 대해 내림차순으로 `선수 이름, 팀 이름, 홈런, 타율, 타점, 장타율`출력

**🛠 구현**: 아래의 3가지 단계로 구현함

```markdown
1. **awk**를 이용하여 홈런 하한, 타율 하한 이상인 선수들 추출
2. `sort -t, -k "$hr_idx,"$hr_idx"" -nr` 를 이용하여 홈런 기준으로 내림차순 정렬
3. **awk**를 이용하여 타석수가 502이상인 선수에 대하여 출력
```

### 6. Generate a performance report (formatted data)

**⚙️ 기능**: 사용자가 입력한 `팀 이름`의 리포트 출력. 리포트에는 오늘 날짜, 해당 팀 선수들의 `이름, 홈런, 타점, 타율, 출루율, OPS`를 홈런 내림차순으로 출력. 마지막 줄에는 해당 팀 총 선수 수를 출력

**🛠 구현**: 아래의 3가지 단계로 구현함

```markdown
1. `date +%Y/%m/%d`를 이용하여 2025/05/06 형식으로 날짜 출력
2. **awk**를 이용하여 사용자가 입력한 팀 이름의 선수들 추출
3. `sort -t, -k "$hr_idx,"$hr_idx"" -nr` 를 이용하여 홈런 기준으로 내림차순 정렬
4. **awk**를 이용하여 선수 정보 출력 후, END로 총 팀 인원 수 출력
```

### 7. Quit

**⚙️ 기능**: `Have a good day!`라는 메세지와 함께 프로그램 종료

**🛠 구현**: **echo**를 통해 메세지 출력 후, 루프문 탈출

## 🤖 실행방법

```bash
./2025_OSS_Project1.sh <csv파일명>
```

위 명령어로 실행합니다.
