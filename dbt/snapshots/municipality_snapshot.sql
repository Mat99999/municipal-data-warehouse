{% snapshot municipality_snapshot %}
{{ config(
    target_schema='warehouse',
    unique_key='municipality_code',
    strategy='check',
    check_cols=['municipality_name', 'region_code', 'region_name'],
    invalidate_hard_deletes=True
) }}
select * from {{ ref('stg_municipalities') }}
{% endsnapshot %}

