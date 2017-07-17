update 
	"contextofdatapoints"
SET
	"XbrlContextKey" = replace("XbrlContextKey",'''','')

select * from contextofdatapoints
--forgatás az exporthoz

select 

--ALO=eba_IM:x1,APL=eba_PL:x4,BAS=eba_BA:x6,MCY=eba_MC:x143

--avm.qname,
--concat('eba_', replace( replace(avm.qname,'{http://www.eba.europa.eu/xbrl/crr/dict/dom/',''),'}',':')) member,
--replace(avd.qname,'{http://www.eba.europa.eu/xbrl/crr/dict/dim}','') dim,
--concat(concat( replace(avd.qname,'{http://www.eba.europa.eu/xbrl/crr/dict/dim}',''),'=')  ,concat('eba_', replace( replace(avm.qname,'{http://www.eba.europa.eu/xbrl/crr/dict/dom/',''),'}',':'))),
--f.fact_id,
--f.value,
-- fc.qname, 
--f.value, f.decimals_value,   
--avd.qname as dim_name, avm.qname as mem_name, av.typed_value, 
--       um.qname as u_measure, um.is_multiplicand as u_mul,p.start_date, p.end_date, p.is_instant, 
--       ei.scheme, ei.identifier 
       

select 
fact_id,
    listagg(replace(avd.qname,'{http://www.eba.europa.eu/xbrl/crr/dict/dim}','') || '='  || 'eba_' || replace( replace(avm.qname,'{http://www.eba.europa.eu/xbrl/crr/dict/dom/',''),'}',':'),',') 
    WITHIN GROUP (order by fact_id)
         OVER (PARTITION BY fact_id,replace(fc.qname,'{http://www.eba.europa.eu/xbrl/crr/dict/met}','eba_AT:')) as dim,
     replace(fc.qname,'{http://www.eba.europa.eu/xbrl/crr/dict/met}','eba_AT:') as met
from fact f 
join concept fc on f.concept_id = fc.concept_id
and f.report_id = 1
left join aspect_value_set av on av.aspect_value_set_id = f.aspect_value_set_id 
join concept avd on av.aspect_concept_id = avd.concept_id 
left join concept avm on av.aspect_value_id = avm.concept_id 
left join unit_measure um on um.unit_id = f.unit_id 
left join period p on p.period_id = f.period_id 
left join entity_identifier ei on ei.entity_identifier_id = f.entity_identifier_id 

order by fact_id

-- select f.fact_id, fc.qname, f.value, f.decimals_value, 
--                                avd.qname as dim_name, avm.qname as mem_name, av.typed_value, 
--                                um.qname as u_measure, um.is_multiplicand as u_mul,p.start_date, p.end_date, p.is_instant, 
--                                ei.scheme, ei.identifier 
--                                from fact f 
--                                join concept fc on f.concept_id = fc.concept_id 
--                                and f.report_id = 1 
--                                left join aspect_value_set av on av.aspect_value_set_id = f.aspect_value_set_id 
--                                join concept avd on av.aspect_concept_id = avd.concept_id 
--                                left join concept avm on av.aspect_value_id = avm.concept_id 
--                                left join unit_measure um on um.unit_id = f.unit_id 
--                                left join period p on p.period_id = f.period_id 
--                                left join entity_identifier ei on ei.entity_identifier_id = f.entity_identifier_id 
--                                where value = '3309000'
-- 
-- 
--   --nulla legyen.
--                                

select distinct * from (

    select 
        fact_id,
        listagg(replace(avd.qname,'{http://www.eba.europa.eu/xbrl/crr/dict/dim}','') || '='  || 'eba_' || replace( replace(avm.qname,'{http://www.eba.europa.eu/xbrl/crr/dict/dom/',''),'}',':'),',') 
        WITHIN GROUP (order by fact_id)
             OVER (PARTITION BY fact_id,replace(fc.qname,'{http://www.eba.europa.eu/xbrl/crr/dict/met}','eba_AT:')) as dim,
         replace(fc.qname,'{http://www.eba.europa.eu/xbrl/crr/dict/met}','eba_AT:') as met
    from fact f 
    join concept fc on f.concept_id = fc.concept_id
    and f.report_id = 1
    left join aspect_value_set av on av.aspect_value_set_id = f.aspect_value_set_id 
    join concept avd on av.aspect_concept_id = avd.concept_id 
    left join concept avm on av.aspect_value_id = avm.concept_id 
    left join unit_measure um on um.unit_id = f.unit_id 
    left join period p on p.period_id = f.period_id 
    left join entity_identifier ei on ei.entity_identifier_id = f.entity_identifier_id 
) result 
inner join member on result.met =  member."MemberXbrlCode"
inner join contextofdatapoints on result.dim = contextofdatapoints."XbrlContextKey"
inner join datapontversion on datapontversion."ContextID" = contextofdatapoints."ContextID"

--select *from contextofdatapoints
--select * from datapointversion
--select * from member

--select memeber."MemberXbrlCode" from member

--select *from "O_DATA_POINTS"