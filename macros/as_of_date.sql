{# Reference date for recency math. Deterministic when `as_of_date` var is set. #}
{% macro as_of_date() -%}
    {%- set d = var('as_of_date', none) -%}
    {%- if d is none -%}current_date(){%- else -%}date('{{ d }}'){%- endif -%}
{%- endmacro %}
