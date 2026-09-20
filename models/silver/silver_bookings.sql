{{ config(materialized="incremental", unique_key="BOOKING_ID") }}
select
    booking_id,
    listing_id,
    booking_date,
    {{ multiply("NIGHTS_BOOKED", "BOOKING_AMOUNT", 2) }} as total_amount,
    service_fee,
    cleaning_fee,
    booking_status,
    created_at
from {{ ref("bronze_bookings") }}
