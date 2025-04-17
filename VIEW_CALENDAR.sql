with date_cte as (
select
    0 as i
,   NULL::date as calendar_date
union all
select
    i + 1 as i
,   dateadd(day, i, '1900-01-01')::date
    from date_cte as c
        where TRUE
        and i < (365.25 * 200) - 1
), calendar_cte as (
select
    c.calendar_date
,   upper(dayname(c.calendar_date)) as day_name_short
,   decode(day_name_short
    ,   'SUN', 'SUNDAY'
    ,   'MON', 'MONDAY'
    ,   'TUE', 'TUESDAY'
    ,   'WED', 'WEDNESDAY'
    ,   'THU', 'THURSDAY'
    ,   'FRI', 'FRIDAY'
    ,   'SAT', 'SATURDAY'
    ) as day_name
,   dayofweek(c.calendar_date) + 1 as day_of_week_number
,   dayofmonth(c.calendar_date) as day_of_month_number
,   dayofyear(c.calendar_date) as day_of_year_number
,   weekofyear(c.calendar_date) as week_number
,   month(c.calendar_date) as month_number
,   quarter(c.calendar_date) as quarter_number
,   year(c.calendar_date) as calendar_year
,   upper(monthname(c.calendar_date)) as month_name_short
,   decode(month_name_short
    ,   'JAN', 'JANUARY'
    ,   'FEB', 'FEBRUARY'
    ,   'MAR', 'MARCH'
    ,   'APR', 'APRIL'
    ,   'MAY', 'MAY'
    ,   'JUN', 'JUNE'
    ,   'JUL', 'JULY'
    ,   'AUG', 'AUGUST'
    ,   'SEP', 'SEPTEMBER'
    ,   'OCT', 'OCTOBER'
    ,   'NOV', 'NOVEMBER'
    ,   'DEC', 'DECEMBER'
    ) as month_name
,   case
        when quarter_number = 1 then '1st'
        when quarter_number = 2 then '2nd'
        when quarter_number = 3 then '3rd'
        when quarter_number = 4 then '4th'
    end as quarter_name_short
,   case
        when quarter_number = 1 then 'FIRST'
        when quarter_number = 2 then 'SECOND'
        when quarter_number = 3 then 'THIRD'
        when quarter_number = 4 then 'FOURTH'
    end as quarter_name
,   case 
        when month_number = 1 then 'WINTER'
        when month_number = 2 then 'WINTER'
        when month_number = 3 and day_of_month_number < 20 then 'WINTER'
        when month_number = 3 and not day_of_month_number < 20 then 'SPRING'
        when month_number = 4 then 'SPRING'
        when month_number = 5 then 'SPRING'
        when month_number = 6 and day_of_month_number < 20 then 'SPRING'
        when month_number = 6 and not day_of_month_number < 20 then 'SUMMER'
        when month_number = 7 then 'SUMMER'
        when month_number = 8 then 'SUMMER'
        when month_number = 9 and day_of_month_number < 20 then 'SUMMER'
        when month_number = 9 and not day_of_month_number < 20 then 'FALL'
        when month_number = 10 then 'FALL'
        when month_number = 11 then 'FALL'
        when month_number = 12 and day_of_month_number < 20 then 'FALL'
        when month_number = 12 and not day_of_month_number < 20 then 'WINTER'
        else 'UNKNOWN'
    end as season_name
,   dateadd(day, 1, c.calendar_date) as calendar_date_tomorrow
,   dateadd(day, -1, c.calendar_date) as calendar_date_yesterday
,   concat(calendar_year, '-', right('0' || week_number, 2)) as year_week
,   concat(calendar_year, '-', right('0' || month_number, 2)) as year_month
,   concat(calendar_year, '-', quarter_number) as year_quarter
,   initcap(concat(day_name, ', ', month_name, ' ', day_of_month_number, ', ', calendar_year)) as calendar_date_description
,   case
        when day_of_week_number not between 2 and 6 then TRUE
        else FALSE
    end as is_weekend
    from date_cte as c
        where TRUE
        and not c.calendar_date is NULL
        and c.calendar_date between '1900-01-01' and '2099-12-31'
)
,   leap_cte as (
select
    c.calendar_year
    from calendar_cte as c
        where TRUE
group by c.calendar_year
having count(distinct c.calendar_date) > 365
)
,   nwyr_cte (holiday_date, holiday) as (
select distinct
-- First day of the calendar year
    case 
        when c.calendar_date >= '1966-09-06' and c.day_of_week_number = 7 then c.calendar_date_yesterday
        when c.calendar_date >= '1966-09-06' and c.day_of_week_number = 1 then c.calendar_date_tomorrow
        else c.calendar_date
    end as holiday_date
,   concat('New Years Day',
    case
        when c.calendar_date != holiday_date then ' (Observed)'
        else ''
    end) as holiday_name
    from calendar_cte as c
        where TRUE
        and c.calendar_year >= 1870
        and c.month_number = 1
        and c.day_of_month_number = 1
)
,   mlkj_cte (holiday_date, holiday) as (
select
-- Third Monday in Janaury since 1986
    c.calendar_date as holiday_date
,   'Martin Luther King Jr Day' as holiday_name
    from calendar_cte as c
        where TRUE
        and c.calendar_year >= 1986
        and c.month_number = 1
        and c.day_of_week_number = 2
qualify (
    -- 3rd
    rank() over (partition by c.calendar_year, case when c.day_of_week_number = 2 then 1 else 0 end order by c.calendar_date asc)) = 3
)
,   wbdy_cte (holiday_date, holiday) as (
-- Third Monday in February since 1879
select
    c.calendar_date as holiday_date
,   'Washington''s Birthday' as holiday_name
    from calendar_cte as c
        where TRUE
        and c.calendar_year >= 1879
        and c.month_number = 2
        and c.day_of_week_number = 2
qualify (
    -- 3rd
    rank() over (partition by c.calendar_year, case when c.day_of_week_number = 2 then 1 else 0 end order by c.calendar_date asc)) = 3
)
,   mmrl_cte (holiday_date, holiday) as (
-- Last Monday in May since 1868
select 
    max(c.calendar_date) as holiday_date
,   'Memorial Day' as holiday_name
    from calendar_cte as c
        where TRUE
        and c.calendar_year >= 1868
        and c.month_number = 5 -- May
        and c.day_of_week_number = 2 -- Monday
group by 
    c.calendar_year
)
,   jnth_cte (holiday_date, holiday) as (
select distinct
-- Nineteenth of June since 2021
    case 
        when c.calendar_date >= '1966-09-06' and c.day_of_week_number = 7 then c.calendar_date_yesterday
        when c.calendar_date >= '1966-09-06' and c.day_of_week_number = 1 then c.calendar_date_tomorrow
        else c.calendar_date
    end as holiday_date
,   concat('Juneteenth'
    ,   case 
            when holiday_date != c.calendar_date then ' (Observed)'
            else ''
        end
    ) as holiday_name
    from calendar_cte as c
        where TRUE
        and c.calendar_year >= 2021
        and c.month_number = 6 -- June
        and c.day_of_month_number = 19
)
,   jul4_cte (holiday_date, holiday) as (
select distinct
-- 4th day of July since 1777
    case 
        when c.calendar_date >= '1966-09-06' and c.day_of_week_number = 7 then c.calendar_date_yesterday
        when c.calendar_date >= '1966-09-06' and c.day_of_week_number = 1 then c.calendar_date_tomorrow
        else c.calendar_date
    end as holiday_date
,   concat('Independence Day' 
    ,   case
            when holiday_date != c.calendar_date then ' (Observed)'
            else ''
        end
    ) as holiday_name
    from calendar_cte as c
        where TRUE
        and c.calendar_year >= 1777
        and c.month_number = 7
        and c.day_of_month_number = 4
)
,   labr_cte (holiday_date, holiday) as (
-- First Monday in September since 1894
select
    min(c.calendar_date) as holiday_date
,   'Labor Day' as holiday_name
    from calendar_cte as c
        where TRUE
        and c.calendar_year >= 1894
        and c.month_number = 9
        and c.day_of_week_number = 2 -- Monday
group by
    c.calendar_year
)
,   ccdy_cte (holiday_date, holiday) as (
select
    s.holiday_date
,   'Columbus Day' as holiday_name
    from (
    select
    -- Original formula: 12th day in October from 1937 to 1970
        c.calendar_date as holiday_date
        from calendar_cte as c
            where TRUE
            and c.calendar_year between 1937 and 1970
            and c.month_number = 10
            and c.day_of_month_number = 12
    union all
    select
    -- Current formula: 2nd Monday in October
        c.calendar_date as holiday_date
        from calendar_cte as c
            where TRUE
            and c.calendar_year >= 1971
            and c.month_number = 10
            and c.day_of_week_number = 2 -- Monday
    qualify (
        -- 2nd
        rank() over (partition by c.calendar_year, case when c.day_of_week_number = 2 then 1 else 0 end order by c.calendar_date asc) = 2)
    ) as s
)
,   vets_cte (holiday_date, holiday) as (
select distinct
-- 11th day in November
    case 
        when c.calendar_date >= '1966-09-06' and c.day_of_week_number = 7 then c.calendar_date_yesterday
        when c.calendar_date >= '1966-09-06' and c.day_of_week_number = 1 then c.calendar_date_tomorrow
        else c.calendar_date
    end as holiday_date
,   concat('Veterans Day',
    case
        when holiday_date != c.calendar_date then ' (Observed)'
        else ''
    end) as holiday_name
    from calendar_cte as c
        where TRUE
        and c.calendar_year >= 1919
        and c.month_number = 11
        and c.day_of_month_number = 11
)
,   thnx_cte (holiday_date, holiday) as (
select 
    s.holiday_date
,   'Thanksgiving Day' as holiday_name
    from (
    select
    -- Original formula: Last Thursday between 1863 and 1941
        max(c.calendar_date) as holiday_date
        from calendar_cte as c
            where TRUE
            and c.calendar_year between 1863 and 1941
            and c.month_number = 11
            and c.day_of_week_number = 5
    group by 
        c.calendar_year
    union all
    select
    -- Current formula: Fourth Thursday in November since 1942
        c.calendar_date as holiday_date
        from calendar_cte as c
            where TRUE
            and c.calendar_year > 1941
            and c.month_number = 11
            and c.day_of_week_number = 5
    qualify (
        rank() over (partition by c.calendar_year, case when c.day_of_week_number = 5 then 1 else 0 end order by c.calendar_date asc) = 4)
    ) as s
)
,   xmas_cte (holiday_date, holiday) as (
select distinct
-- 25th day in December
    case 
        when c.calendar_date >= '1966-09-06' and c.day_of_week_number = 7 then c.calendar_date_yesterday
        when c.calendar_date >= '1966-09-06' and c.day_of_week_number = 1 then c.calendar_date_tomorrow
        else c.calendar_date
    end as holiday_date
,   concat('Christmas Day', 
    case
        when holiday_date != c.calendar_date then ' (Observed)'
        else ''
    end) as holiday_name
    from calendar_cte as c
        where TRUE
        and c.month_number = 12
        and c.day_of_month_number = 25
)
select
    cal.* exclude (is_weekend)
,   case
        when nyd.holiday is not NULL then nyd.holiday
        when mlk.holiday is not NULL then mlk.holiday
        when was.holiday is not NULL then was.holiday
        when mem.holiday is not NULL then mem.holiday
        when jun.holiday is not NULL then jun.holiday
        when jl4.holiday is not NULL then jl4.holiday
        when lab.holiday is not NULL then lab.holiday
        when col.holiday is not NULL then col.holiday
        when vet.holiday is not NULL then vet.holiday
        when thx.holiday is not NULL then thx.holiday
        when xms.holiday is not NULL then xms.holiday
        else NULL -- Not a recognized federal holiday
    end as holiday_name
,   cal.is_weekend
,   case 
        when holiday_name is not NULL then TRUE 
        else FALSE 
    end as is_holiday
,   case
        when lep.calendar_year is not NULL then TRUE
        else FALSE
    end as is_leap_year
    from calendar_cte as cal
    left join leap_cte as lep on cal.calendar_year = lep.calendar_year
    left join nwyr_cte as nyd on cal.calendar_date = nyd.holiday_date
    left join mlkj_cte as mlk on cal.calendar_date = mlk.holiday_date
    left join wbdy_cte as was on cal.calendar_date = was.holiday_date
    left join mmrl_cte as mem on cal.calendar_date = mem.holiday_date
    left join jnth_cte as jun on cal.calendar_date = jun.holiday_date
    left join jul4_cte as jl4 on cal.calendar_date = jl4.holiday_date
    left join labr_cte as lab on cal.calendar_date = lab.holiday_date
    left join ccdy_cte as col on cal.calendar_date = col.holiday_date
    left join vets_cte as vet on cal.calendar_date = vet.holiday_date
    left join thnx_cte as thx on cal.calendar_date = thx.holiday_date
    left join xmas_cte as xms on cal.calendar_date = xms.holiday_date
        where TRUE
        AND cal.calendar_year between 2020 and 2026
order by 
    case
        when calendar_year = year(current_date()) then 0 else 1
    end asc
,   cal.calendar_date asc
;