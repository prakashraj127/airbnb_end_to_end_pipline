{{ config(materialized="incremental", unique_key="LISTING_ID") }}

select
    listing_id,
    host_id,
    property_type,
    room_type,
    city,
    country,
    accommodates,
    bedrooms,
    bathrooms,
    price_per_night,
    {{ tag("CAST(PRICE_PER_NIGHT AS INT)") }} as price_per_night_tag,
    created_at
from {{ ref("bronze_listings") }}
