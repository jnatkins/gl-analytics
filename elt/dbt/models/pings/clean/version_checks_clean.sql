with version60 as (
  SELECT * FROM {{ ref('last60versionpings') }}
)

SELECT
  curls.clean_domain      AS clean_url,
  curls.clean_full_domain AS clean_full_url,
  version60.*
FROM
  version60
  JOIN public.cleaned_urls AS curls ON version60.referer_url = curls.domain



