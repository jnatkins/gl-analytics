{{ simple_cte([
    ('dim_crm_person','dim_crm_person')
]) }},

crm_person AS (

  SELECT
    dim_crm_person_id,
    leandata_matched_account_sales_segment,
    employee_bucket,
    COALESCE(
      account_demographics_employee_count,
      zoominfo_company_employee_count,
      cognism_employee_count) AS employee_count,
    LOWER(COALESCE(
      zoominfo_company_country,
      zoominfo_contact_country,
      cognism_company_office_country,
      cognism_country)) AS first_country
  FROM dim_crm_person
)

SELECT
  dim_crm_person_id,
  CASE
    WHEN LOWER(leandata_matched_account_sales_segment) = 'pubsec' THEN 'PubSec'
    WHEN employee_count >= 1 AND employee_count < 100 THEN 'SMB'
    WHEN employee_count >= 100 AND employee_count < 2000 THEN 'MM'
    WHEN employee_count >= 2000 THEN 'Large'
    ELSE 'Unknown'
  END AS employee_count_segment_custom,
  CASE
    WHEN LOWER(leandata_matched_account_sales_segment) = 'pubsec' THEN 'PubSec'
    WHEN employee_bucket = '1-99' THEN 'SMB'
    WHEN employee_bucket = '100-499' THEN 'MM'
    WHEN employee_bucket = '500-1,999' THEN 'MM'
    WHEN employee_bucket = '2,000-9,999' THEN 'Large'
    WHEN employee_bucket = '10,000+' THEN 'Large'
    ELSE 'Unknown'
  END AS employee_bucket_segment_custom,
  CASE
    WHEN first_country = 'afghanistan' THEN 'emea'
    WHEN first_country = 'aland islands' THEN 'emea'
    WHEN first_country = 'albania' THEN 'emea'
    WHEN first_country = 'algeria' THEN 'emea'
    WHEN first_country = 'andorra' THEN 'emea'
    WHEN first_country = 'angola' THEN 'emea'
    WHEN first_country = 'anguilla' THEN 'amer'
    WHEN first_country = 'antigua and barbuda' THEN 'amer'
    WHEN first_country = 'argentina' THEN 'amer'
    WHEN first_country = 'armenia' THEN 'emea'
    WHEN first_country = 'aruba' THEN 'amer'
    WHEN first_country = 'australia' THEN 'apac'
    WHEN first_country = 'austria' THEN 'emea'
    WHEN first_country = 'azerbaijan' THEN 'emea'
    WHEN first_country = 'bahamas' THEN 'amer'
    WHEN first_country = 'bahrain' THEN 'emea'
    WHEN first_country = 'bangladesh' THEN 'apac'
    WHEN first_country = 'barbados' THEN 'amer'
    WHEN first_country = 'belarus' THEN 'emea'
    WHEN first_country = 'belgium' THEN 'emea'
    WHEN first_country = 'belize' THEN 'amer'
    WHEN first_country = 'benin' THEN 'emea'
    WHEN first_country = 'bermuda' THEN 'amer'
    WHEN first_country = 'bhutan' THEN 'apac'
    WHEN first_country = 'bolivia' THEN 'amer'
    WHEN first_country = 'bosnia and herzegovina' THEN 'emea'
    WHEN first_country = 'bosnia and herzegowina' THEN 'emea'
    WHEN first_country = 'botswana' THEN 'emea'
    WHEN first_country = 'brazil' THEN 'amer'
    WHEN first_country = 'british virgin islands' THEN 'amer'
    WHEN first_country = 'brunei darussalam' THEN 'apac'
    WHEN first_country = 'bulgaria' THEN 'emea'
    WHEN first_country = 'burkina faso' THEN 'emea'
    WHEN first_country = 'burundi' THEN 'emea'
    WHEN first_country = 'cambodia' THEN 'apac'
    WHEN first_country = 'cameroon' THEN 'emea'
    WHEN first_country = 'canada' THEN 'amer'
    WHEN first_country = 'cape verde' THEN 'emea'
    WHEN first_country = 'caribbean netherlands' THEN 'amer'
    WHEN first_country = 'cayman islands' THEN 'amer'
    WHEN first_country = 'central african republic' THEN 'emea'
    WHEN first_country = 'chad' THEN 'emea'
    WHEN first_country = 'chile' THEN 'amer'
    WHEN first_country = 'china' THEN 'jihu'
    WHEN first_country = 'colombia' THEN 'amer'
    WHEN first_country = 'comoros' THEN 'emea'
    WHEN first_country = 'congo' THEN 'emea'
    WHEN first_country = 'cook islands' THEN 'apac'
    WHEN first_country = 'costa rica' THEN 'amer'
    WHEN first_country LIKE 'cote' AND first_country LIKE 'ivoire' THEN 'emea'
    WHEN first_country = 'croatia' THEN 'emea'
    WHEN first_country = 'cuba' THEN 'amer'
    WHEN first_country = 'curacao' THEN 'amer'
    WHEN first_country = 'cyprus' THEN 'emea'
    WHEN first_country = 'czech republic' THEN 'emea'
    WHEN first_country = 'democratic republic of the congo' THEN 'emea'
    WHEN first_country = 'denmark' THEN 'emea'
    WHEN first_country = 'djibouti' THEN 'emea'
    WHEN first_country = 'dominica' THEN 'amer'
    WHEN first_country = 'dominican republic' THEN 'amer'
    WHEN first_country = 'ecuador' THEN 'amer'
    WHEN first_country = 'egypt' THEN 'emea'
    WHEN first_country = 'el salvador' THEN 'amer'
    WHEN first_country = 'equatorial guinea' THEN 'emea'
    WHEN first_country = 'eritrea' THEN 'emea'
    WHEN first_country = 'estonia' THEN 'emea'
    WHEN first_country = 'eswatini' THEN 'emea'
    WHEN first_country = 'ethiopia' THEN 'emea'
    WHEN first_country = 'falkland islands' THEN 'amer'
    WHEN first_country = 'faroe islands' THEN 'emea'
    WHEN first_country = 'fiji' THEN 'apac'
    WHEN first_country = 'finland' THEN 'emea'
    WHEN first_country = 'france' THEN 'emea'
    WHEN first_country = 'french guiana' THEN 'amer'
    WHEN first_country = 'french polynesia' THEN 'apac'
    WHEN first_country = 'gabon' THEN 'emea'
    WHEN first_country = 'gambia' THEN 'emea'
    WHEN first_country = 'georgia' THEN 'emea'
    WHEN first_country = 'germany' THEN 'emea'
    WHEN first_country = 'ghana' THEN 'emea'
    WHEN first_country = 'gibraltar' THEN 'emea'
    WHEN first_country = 'greece' THEN 'emea'
    WHEN first_country = 'greenland' THEN 'emea'
    WHEN first_country = 'grenada' THEN 'amer'
    WHEN first_country = 'guadeloupe' THEN 'amer'
    WHEN first_country = 'guatemala' THEN 'amer'
    WHEN first_country = 'guernsey' THEN 'emea'
    WHEN first_country = 'guinea' THEN 'emea'
    WHEN first_country = 'guinea-bissau' THEN 'emea'
    WHEN first_country = 'guyana' THEN 'amer'
    WHEN first_country = 'haiti' THEN 'amer'
    WHEN first_country = 'honduras' THEN 'amer'
    WHEN first_country = 'hungary' THEN 'emea'
    WHEN first_country = 'iceland' THEN 'emea'
    WHEN first_country = 'india' THEN 'apac'
    WHEN first_country = 'indonesia' THEN 'apac'
    WHEN first_country = 'iran' THEN 'emea'
    WHEN first_country = 'iran' THEN 'emea'
    WHEN first_country = 'iran, islamic republic of' THEN 'emea'
    WHEN first_country = 'ireland' THEN 'emea'
    WHEN first_country = 'isle of man' THEN 'emea'
    WHEN first_country = 'israel' THEN 'emea'
    WHEN first_country = 'italy' THEN 'emea'
    WHEN first_country = 'ivory coast' THEN 'emea'
    WHEN first_country LIKE 'côte d' AND first_country LIKE 'ivoire' THEN 'emea'
    WHEN first_country = 'jamaica' THEN 'amer'
    WHEN first_country = 'japan' THEN 'apac'
    WHEN first_country = 'jersey' THEN 'emea'
    WHEN first_country = 'jordan' THEN 'emea'
    WHEN first_country = 'kazakhstan' THEN 'emea'
    WHEN first_country = 'kenya' THEN 'emea'
    WHEN first_country = 'kosovo' THEN 'emea'
    WHEN first_country = 'kuwait' THEN 'emea'
    WHEN first_country = 'kyrgyzstan' THEN 'emea'
    WHEN first_country LIKE 'lao people' AND first_country LIKE 'democratic republic' THEN 'apac'
    WHEN first_country = 'latvia' THEN 'emea'
    WHEN first_country = 'lebanon' THEN 'emea'
    WHEN first_country = 'lesotho' THEN 'emea'
    WHEN first_country = 'liberia' THEN 'emea'
    WHEN first_country = 'libya' THEN 'emea'
    WHEN first_country = 'liechtenstein' THEN 'emea'
    WHEN first_country = 'lithuania' THEN 'emea'
    WHEN first_country = 'luxembourg' THEN 'emea'
    WHEN first_country = 'macao' THEN 'jihu'
    WHEN first_country = 'macedonia' THEN 'emea'
    WHEN first_country = 'madagascar' THEN 'emea'
    WHEN first_country = 'malawi' THEN 'emea'
    WHEN first_country = 'malaysia' THEN 'apac'
    WHEN first_country = 'maldives' THEN 'apac'
    WHEN first_country = 'mali' THEN 'emea'
    WHEN first_country = 'malta' THEN 'emea'
    WHEN first_country = 'martinique' THEN 'amer'
    WHEN first_country = 'mauritania' THEN 'emea'
    WHEN first_country = 'mauritius' THEN 'emea'
    WHEN first_country = 'mayotte' THEN 'emea'
    WHEN first_country = 'mexico' THEN 'amer'
    WHEN first_country = 'moldova' THEN 'emea'
    WHEN first_country = 'monaco' THEN 'emea'
    WHEN first_country = 'mongolia' THEN 'apac'
    WHEN first_country = 'montenegro' THEN 'emea'
    WHEN first_country = 'montserrat' THEN 'amer'
    WHEN first_country = 'morocco' THEN 'emea'
    WHEN first_country = 'mozambique' THEN 'emea'
    WHEN first_country = 'myanmar' THEN 'apac'
    WHEN first_country = 'namibia' THEN 'emea'
    WHEN first_country = 'nauru' THEN 'apac'
    WHEN first_country = 'nepal' THEN 'apac'
    WHEN first_country = 'netherlands' THEN 'emea'
    WHEN first_country = 'new caledonia' THEN 'apac'
    WHEN first_country = 'new zealand' THEN 'apac'
    WHEN first_country = 'nicaragua' THEN 'amer'
    WHEN first_country = 'niger' THEN 'emea'
    WHEN first_country = 'nigeria' THEN 'emea'
    WHEN first_country = 'north macedonia' THEN 'emea'
    WHEN first_country = 'norway' THEN 'emea'
    WHEN first_country = 'oman' THEN 'emea'
    WHEN first_country = 'pakistan' THEN 'emea'
    WHEN first_country = 'palestine' THEN 'emea'
    WHEN first_country = 'palestine, state of' THEN 'emea'
    WHEN first_country = 'panama' THEN 'amer'
    WHEN first_country = 'papua new guinea' THEN 'apac'
    WHEN first_country = 'paraguay' THEN 'amer'
    WHEN first_country = 'peru' THEN 'amer'
    WHEN first_country = 'philippines' THEN 'apac'
    WHEN first_country = 'poland' THEN 'emea'
    WHEN first_country = 'portugal' THEN 'emea'
    WHEN first_country = 'puerto rico' THEN 'amer'
    WHEN first_country = 'qatar' THEN 'emea'
    WHEN first_country = 'reunion' THEN 'emea'
    WHEN first_country = 'romania' THEN 'emea'
    WHEN first_country = 'russia' THEN 'emea'
    WHEN first_country = 'rwanda' THEN 'emea'
    WHEN first_country = 'saint helena' THEN 'emea'
    WHEN first_country = 'saint kitts and nevis' THEN 'amer'
    WHEN first_country = 'saint lucia' THEN 'amer'
    WHEN first_country = 'saint martin' THEN 'amer'
    WHEN first_country = 'saint vincent and the grenadines' THEN 'amer'
    WHEN first_country = 'samoa' THEN 'apac'
    WHEN first_country = 'san marino' THEN 'emea'
    WHEN first_country = 'sao tome and principe' THEN 'emea'
    WHEN first_country = 'saudi arabia' THEN 'emea'
    WHEN first_country = 'senegal' THEN 'emea'
    WHEN first_country = 'serbia' THEN 'emea'
    WHEN first_country = 'seychelles' THEN 'emea'
    WHEN first_country = 'sierra leone' THEN 'emea'
    WHEN first_country = 'singapore' THEN 'apac'
    WHEN first_country = 'sint maarten' THEN 'amer'
    WHEN first_country = 'slovakia' THEN 'emea'
    WHEN first_country = 'slovenia' THEN 'emea'
    WHEN first_country = 'solomon islands' THEN 'apac'
    WHEN first_country = 'somalia' THEN 'emea'
    WHEN first_country = 'south africa' THEN 'emea'
    WHEN first_country = 'south korea' THEN 'apac'
    WHEN first_country = 'south sudan' THEN 'emea'
    WHEN first_country = 'spain' THEN 'emea'
    WHEN first_country = 'españa' THEN 'emea'
    WHEN first_country = 'sri lanka' THEN 'apac'
    WHEN first_country = 'sudan' THEN 'emea'
    WHEN first_country = 'suriname' THEN 'amer'
    WHEN first_country = 'swaziland' THEN 'emea'
    WHEN first_country = 'sweden' THEN 'emea'
    WHEN first_country = 'switzerland' THEN 'emea'
    WHEN first_country = 'syria' THEN 'emea'
    WHEN first_country = 'taiwan' THEN 'apac'
    WHEN first_country = 'taiwan, province of china' THEN 'apac'
    WHEN first_country = 'tajikistan' THEN 'emea'
    WHEN first_country = 'tanzania' THEN 'emea'
    WHEN first_country = 'united republic of tanzania' THEN 'emea'
    WHEN first_country = 'thailand' THEN 'apac'
    WHEN first_country = 'the netherlands' THEN 'emea'
    WHEN first_country = 'timor-leste' THEN 'apac'
    WHEN first_country = 'togo' THEN 'emea'
    WHEN first_country = 'tonga' THEN 'apac'
    WHEN first_country = 'trinidad and tobago' THEN 'amer'
    WHEN first_country = 'tunisia' THEN 'emea'
    WHEN first_country = 'turkey' THEN 'emea'
    WHEN first_country = 'turkmenistan' THEN 'emea'
    WHEN first_country = 'turks and caicos islands' THEN 'amer'
    WHEN first_country = 'u.s. virgin islands' THEN 'amer'
    WHEN first_country = 'uganda' THEN 'emea'
    WHEN first_country = 'ukraine' THEN 'emea'
    WHEN first_country = 'united arab emirates' THEN 'emea'
    WHEN first_country = 'united kingdom' THEN 'emea'
    WHEN first_country = 'uruguay' THEN 'amer'
    WHEN first_country = 'uzbekistan' THEN 'emea'
    WHEN first_country = 'vanuatu' THEN 'apac'
    WHEN first_country = 'vatican' THEN 'emea'
    WHEN first_country = 'venezuela' THEN 'amer'
    WHEN first_country = 'vietnam' THEN 'apac'
    WHEN first_country = 'western sahara' THEN 'emea'
    WHEN first_country = 'yemen' THEN 'emea'
    WHEN first_country = 'zambia' THEN 'emea'
    WHEN first_country = 'zimbabwe' THEN 'emea'
    WHEN first_country = 'united states' THEN 'amer'
    WHEN first_country = 'turks and caicos' THEN 'amer'
    WHEN first_country = 'korea, republic of' THEN 'apac'
    WHEN first_country LIKE 'lao democratic people' AND first_country LIKE 's republic' THEN 'apac'
    WHEN first_country = 'macedonia, the former yugoslav republic of' THEN 'emea'
    WHEN first_country = 'moldova, republic of' THEN 'emea'
    WHEN first_country = 'russian federation' THEN 'emea'
    WHEN first_country = 'viet nam' THEN 'apac'
  END AS geo_custom
FROM crm_person
