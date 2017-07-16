-- This DDL (SQL) script initializes a database for the XBRL Abstract Model using Postgres

-- (c) Copyright 2013 Mark V Systems Limited, California US, All rights reserved.  
-- Mark V copyright applies to this software, which is licensed according to the terms of Arelle(r).
set define off;

-- drop triggers
begin
   for t in (select trigger_name from user_triggers)
   loop
       execute immediate 'drop trigger ' || t.trigger_name;
   end loop;
end;
/

-- drop tables
begin
   for t in (select table_name from user_tables)
   loop
       execute immediate 'drop table ' || t.table_name || ' CASCADE CONSTRAINTS PURGE ';
   end loop;
end;
/
-- drop sequences
begin
   for s in (select sequence_name from user_sequences)
   loop
       execute immediate 'drop sequence ' || s.sequence_name;
   end loop;
end;
/
--@notok
CREATE SEQUENCE seq_filing;

CREATE TABLE filing (
    filing_id number(19) NOT NULL,
    filing_number varchar2(32) NOT NULL, -- SEC accession number
    legal_entity_number varchar2(30), -- LEI
    reference_number varchar2(30), -- external code, e.g. CIK (which may change for an entity during entity's life)
    standard_industry_code integer,
    tax_number varchar2(30),
    form_type varchar2(30),
    accepted_timestamp date DEFAULT sysdate,
    is_most_current number(1) DEFAULT 0,
    filing_date date NOT NULL,
    creation_software varchar2(4000),
    authority_html_url varchar2(4000),
    entry_url varchar2(4000),
    fiscal_year  varchar2(6),
    fiscal_period  varchar2(30),
    name_at_filing  varchar2(30),
    legal_state_at_filing varchar2(30),
    restatement_index  varchar2(6),
    period_index  varchar2(6),
    first_5_comments  varchar2(30),
    zip_url varchar2(4000),
    file_number  varchar2(30), -- authority internal number
    phone  varchar2(30),
    phys_addr1  varchar2(30), -- physical (real) address
    phys_addr2  varchar2(30),
    phys_city  varchar2(30),
    phys_state  varchar2(30),
    phys_zip  varchar2(30),
    phys_country  varchar2(30),
    mail_addr1  varchar2(30), -- mailing (postal) address
    mail_addr2  varchar2(30),
    mail_city  varchar2(30),
    mail_state  varchar2(30),
    mail_zip  varchar2(30),
    mail_country  varchar2(30),
    fiscal_year_end  varchar2(6),
    filer_category  varchar2(30),
    public_float float,
    trading_symbol  varchar2(30),
    PRIMARY KEY (filing_id)
);
CREATE INDEX filing_index02 ON filing (filing_number);
CREATE INDEX filing_index03 ON filing (reference_number);
CREATE INDEX filing_index04 ON filing (legal_entity_number);


CREATE TRIGGER filing_insert_trigger BEFORE INSERT ON filing
  FOR EACH ROW
    BEGIN
       SELECT seq_filing.NEXTVAL INTO :NEW.filing_id from dual;
    END;
/
-- object sequence can be any element that can terminate a relationship (concept, type, resource, data point, document, role type, ...)
-- or be a reference of a message (report or any of above)
CREATE SEQUENCE seq_object;

CREATE TABLE report (
    report_id number(19) NOT NULL,
    filing_id number(19) NOT NULL,
    report_data_doc_id number(19),  -- instance or primary inline document
    report_schema_doc_id number(19),  -- extension schema of the report (primary)
    agency_schema_doc_id number(19),  -- agency schema (receiving authority)
    standard_schema_doc_id number(19)  -- e.g., IFRS, XBRL-US, or EDInet schema
);
CREATE INDEX report_index01 ON report (report_id);
CREATE INDEX report_index02 ON report (filing_id);

CREATE TRIGGER report_insert_trigger BEFORE INSERT ON report
  FOR EACH ROW
    BEGIN
       SELECT seq_object.NEXTVAL INTO :NEW.report_id from dual;
    END;
/


CREATE TABLE document (
    document_id number(19) NOT NULL,
    document_url varchar2(2048) NOT NULL,
    document_type varchar2(32),  -- ModelDocument.Type string value
    namespace varchar2(1024),  -- targetNamespace if schema else NULL
    PRIMARY KEY (document_id)
);
CREATE INDEX document_index02 ON document (document_url) COMPRESS;

CREATE TRIGGER document_insert_trigger BEFORE INSERT ON document
  FOR EACH ROW
    BEGIN
       SELECT seq_object.NEXTVAL INTO :NEW.document_id from dual;
    END;
/
-- documents referenced by report or document

CREATE TABLE referenced_documents (
    object_id number(19) NOT NULL,
    document_id number(19) NOT NULL
);
CREATE INDEX referenced_documents_index01 ON referenced_documents (object_id);
CREATE UNIQUE INDEX referenced_documents_index02 ON referenced_documents (object_id, document_id);


CREATE TABLE concept (
    concept_id number(19) NOT NULL,
    document_id number(19) NOT NULL,
    xml_id varchar2(4000),
    xml_child_seq varchar2(512),
    qname varchar2(1024) NOT NULL,  -- clark notation qname (do we need this?)
    name varchar2(1024) NOT NULL,  -- local qname
    datatype_id number(19),
    base_type varchar2(128), -- xml base type if any
    substitution_group_concept_id number(19),
    balance varchar2(16),
    period_type varchar2(16),
    abstract number(1) NOT NULL,
    nillable number(1) NOT NULL,
    is_numeric number(1) NOT NULL,
    is_monetary number(1) NOT NULL,
    is_text_block number(1) NOT NULL,
    PRIMARY KEY (concept_id)
);
CREATE INDEX concept_index02 ON concept (document_id);
CREATE INDEX concept_index03 ON concept (qname) COMPRESS;

CREATE TRIGGER concept_insert_trigger BEFORE INSERT ON concept
  FOR EACH ROW
    BEGIN
       SELECT seq_object.NEXTVAL INTO :NEW.concept_id from dual;
    END;
/

CREATE TABLE data_type (
    data_type_id number(19) NOT NULL,
    document_id number(19) NOT NULL,
    xml_id varchar2(4000),
    xml_child_seq varchar2(512),
    qname varchar2(1024) NOT NULL,  -- clark notation qname (do we need this?)
    name varchar2(1024) NOT NULL,  -- local qname
    base_type varchar2(128), -- xml base type if any
    derived_from_type_id number(19),
    PRIMARY KEY (data_type_id)
);
CREATE INDEX data_type_index02 ON data_type (document_id);
CREATE INDEX data_type_index03 ON data_type (qname) COMPRESS;

CREATE TRIGGER data_type_insert_trigger BEFORE INSERT ON data_type
  FOR EACH ROW
    BEGIN
       SELECT seq_object.NEXTVAL INTO :NEW.data_type_id from dual;
    END;
/


CREATE TABLE enumeration (
    concept_id number(19) NOT NULL,
    concept_value_id number(19) NOT NULL,
    value varchar2(4000)
);
CREATE INDEX enumeration_index01 ON enumeration (concept_id);
/

CREATE TABLE role_type (
    role_type_id number(19) NOT NULL,
    document_id number(19) NOT NULL,
    xml_id varchar2(4000),
    xml_child_seq varchar2(512),
    role_uri varchar2(1024) NOT NULL,
    definition varchar2(4000),
    PRIMARY KEY (role_type_id)
);
CREATE INDEX role_type_index02 ON role_type (document_id);
CREATE INDEX role_type_index03 ON role_type (role_uri) COMPRESS;

CREATE TRIGGER role_type_insert_trigger BEFORE INSERT ON role_type
  FOR EACH ROW
    BEGIN
       SELECT seq_object.NEXTVAL INTO :NEW.role_type_id from dual;
    END;
/

CREATE TABLE arcrole_type (
    arcrole_type_id number(19) NOT NULL,
    document_id number(19) NOT NULL,
    xml_id varchar2(4000),
    xml_child_seq varchar2(512),
    arcrole_uri varchar2(1024) NOT NULL,
    cycles_allowed varchar2(10) NOT NULL,
    definition varchar2(4000),
    PRIMARY KEY (arcrole_type_id)
);
CREATE INDEX arcrole_type_index02 ON arcrole_type (document_id);
CREATE INDEX arcrole_type_index03 ON arcrole_type (arcrole_uri) COMPRESS;

CREATE TRIGGER arcrole_type_insert_trigger BEFORE INSERT ON arcrole_type
  FOR EACH ROW
    BEGIN
       SELECT seq_object.NEXTVAL INTO :NEW.arcrole_type_id from dual;
    END;
/

CREATE TABLE used_on (
    object_id number(19) NOT NULL,
    concept_id number(19) NOT NULL
);
CREATE INDEX used_on_index01 ON used_on (object_id);
CREATE UNIQUE INDEX used_on_index02 ON used_on (object_id, concept_id);
/

CREATE TABLE resources (
    resource_id number(19) NOT NULL,
    document_id number(19) NOT NULL,
    xml_id varchar2(4000),
    xml_child_seq varchar2(512),
    qname varchar2(1024) NOT NULL,  -- clark notation qname (do we need this?)
    role varchar2(1024),
    value nclob,
    xml_lang varchar2(16),
    PRIMARY KEY (resource_id)
);
CREATE UNIQUE INDEX resource_index02 ON resources (document_id, xml_child_seq);

CREATE TRIGGER resource_insert_trigger BEFORE INSERT ON resources
  FOR EACH ROW
    BEGIN
       SELECT seq_object.NEXTVAL INTO :NEW.resource_id from dual;
    END;
/

CREATE SEQUENCE seq_relationship_set;

CREATE TABLE relationship_set (
    relationship_set_id number(19) NOT NULL,
    document_id number(19) NOT NULL,
    arc_qname varchar2(1024) NOT NULL,  -- clark notation qname (do we need this?)
    link_qname varchar2(1024) NOT NULL,  -- clark notation qname (do we need this?)
    arc_role varchar2(1024) NOT NULL,
    link_role varchar2(1024) NOT NULL,
    PRIMARY KEY (relationship_set_id)
);
CREATE INDEX relationship_set_index02 ON relationship_set (document_id);
CREATE INDEX relationship_set_index03 ON relationship_set (link_role) COMPRESS;
CREATE INDEX relationship_set_index04 ON relationship_set (arc_role) COMPRESS;

CREATE TRIGGER rel_set_insert_trigger BEFORE INSERT ON relationship_set
  FOR EACH ROW
    BEGIN
       SELECT seq_relationship_set.NEXTVAL INTO :NEW.relationship_set_id from dual;
    END;
/

CREATE TABLE root (
    relationship_set_id number(19) NOT NULL,
    relationship_id number(19) NOT NULL
);
CREATE INDEX root_index02 ON root (relationship_set_id);
/
CREATE TABLE relationship (
    relationship_id number(19) NOT NULL,
    document_id number(19) NOT NULL,
    xml_id varchar2(4000),
    xml_child_seq varchar2(512),
    relationship_set_id number(19) NOT NULL,
    reln_order binary_double,
    from_id number(19),
    to_id number(19),
    calculation_weight binary_double,
    tree_sequence integer NOT NULL,
    tree_depth integer NOT NULL,
    preferred_label_role varchar2(1024),
    PRIMARY KEY (relationship_id)
);
CREATE INDEX relationship_index02 ON relationship (relationship_set_id);
CREATE INDEX relationship_index03 ON relationship (relationship_set_id, tree_depth);
CREATE INDEX relationship_index04 ON relationship (relationship_set_id, document_id, xml_child_seq);
CREATE INDEX relationship_index05 ON relationship (from_id);

CREATE TRIGGER relationship_insert_trigger BEFORE INSERT ON relationship
  FOR EACH ROW
    BEGIN
       SELECT seq_object.NEXTVAL INTO :NEW.relationship_id from dual;
    END;
/
CREATE TABLE fact (
    fact_id number(19) NOT NULL,
    report_id number(19),
    document_id number(19) NOT NULL,  -- multiple inline documents are sources of data points
    xml_id varchar2(4000),
    xml_child_seq varchar2(512),
    source_line integer,
    tuple_fact_id number(19), -- id of tuple parent
    concept_id number(19) NOT NULL,
    context_xml_id varchar2(1024), -- (max observed length 693 in SEC 2012-2014)
    entity_identifier_id number(19),
    period_id number(19),
    aspect_value_set_id number(19),
    unit_id number(19),
    is_nil number(1) DEFAULT 0,
    precision_value varchar2(16),
    decimals_value varchar2(16),
    effective_value binary_double,
    language  varchar2(16), -- for string-valued facts else NULL
    normalized_string_value varchar2(4000),
    value varchar2(4000),
    PRIMARY KEY (fact_id)
);
CREATE INDEX fact_index02 ON fact (document_id, xml_child_seq);
CREATE INDEX fact_index03 ON fact (report_id);
CREATE INDEX fact_index04 ON fact (concept_id);

CREATE TRIGGER fact_insert_trigger BEFORE INSERT ON fact
  FOR EACH ROW
    BEGIN
       SELECT seq_object.NEXTVAL INTO :NEW.fact_id from dual;
    END;
/

CREATE TABLE footnote (
    fact_id number(19) NOT NULL,
    footnote_group varchar2(1024),
    type varchar2(1024),
    footnote_value_id varchar2(1024),
    language varchar2(30),
    normalized_string_value varchar2(4000),
    value varchar2(4000)
);
CREATE INDEX footnote_index01 ON footnote (fact_id);

/
CREATE TABLE entity_identifier (
    entity_identifier_id number(19) NOT NULL,
    report_id number(19),
    scheme varchar2(1024) NOT NULL,
    identifier varchar2(1024) NOT NULL,
    PRIMARY KEY (entity_identifier_id)
);
CREATE INDEX entity_identifier_index02 ON entity_identifier (report_id, scheme, identifier);

CREATE TRIGGER entity_insert_trigger BEFORE INSERT ON entity_identifier
  FOR EACH ROW
    BEGIN
       SELECT seq_object.NEXTVAL INTO :NEW.entity_identifier_id from dual;
    END;
/
CREATE TABLE period (
    period_id number(19) NOT NULL,
    report_id number(19),
    start_date date,
    end_date date,
    is_instant number(1) NOT NULL,
    is_forever number(1) NOT NULL,
    PRIMARY KEY (period_id)
);
CREATE INDEX period_index02 ON period (report_id, start_date, end_date, is_instant, is_forever);

CREATE TRIGGER period_insert_trigger BEFORE INSERT ON period
  FOR EACH ROW
    BEGIN
       SELECT seq_object.NEXTVAL INTO :NEW.period_id from dual;
    END;
/

CREATE TABLE unit (
    unit_id number(19) NOT NULL,
    report_id number(19),
    xml_id varchar2(4000),
    xml_child_seq varchar2(512),
    measures_hash varchar2(36),
    PRIMARY KEY (unit_id)
);
CREATE INDEX unit_index02 ON unit (report_id, measures_hash);

CREATE TRIGGER unit_insert_trigger BEFORE INSERT ON unit
  FOR EACH ROW
    BEGIN
       SELECT seq_object.NEXTVAL INTO :NEW.unit_id from dual;
    END;
/
CREATE TABLE unit_measure (
    unit_id number(19) NOT NULL,
    qname varchar2(1024) NOT NULL,  -- clark notation qname (do we need this?)
    is_multiplicand number(1) NOT NULL
);
CREATE INDEX unit_measure_index01 ON unit_measure (unit_id);
CREATE INDEX unit_measure_index02 ON unit_measure (unit_id, qname, is_multiplicand);
/
-- table to create aspect_value_set_id's for a report's aspect_value_sets
CREATE TABLE aspect_value_report_set (
    aspect_value_set_id number(19) NOT NULL,
    report_id number(19)
);
CREATE INDEX aspect_value_report_set_idx01 ON aspect_value_report_set (report_id);
CREATE TRIGGER aspect_value_rep_ins_trigger BEFORE INSERT ON aspect_value_report_set
  FOR EACH ROW
    BEGIN
       SELECT seq_object.NEXTVAL INTO :NEW.aspect_value_set_id from dual;
    END;
/


CREATE TABLE aspect_value_set (
    aspect_value_set_id number(19) NOT NULL, -- index assigned by aspect_value_report_set
    aspect_concept_id number(19) NOT NULL,
    aspect_value_id number(19),
    is_typed_value number(1) NOT NULL,
    typed_value varchar2(4000)
);
CREATE INDEX aspect_value_setindex01 ON aspect_value_set (aspect_value_set_id);
CREATE INDEX aspect_value_setindex02 ON aspect_value_set (aspect_concept_id);
/

CREATE TABLE table_facts(
    report_id number(19),
    object_id number(19) NOT NULL, -- may be any role_type or concept defining a table table with 'seq_object' id
    table_code varchar2(16),  -- short code of table, like BS, PL, or 4.15.221
    fact_id number(19) -- id of fact in this table (according to its concepts)
);
CREATE INDEX table_facts_index01 ON table_facts (report_id);
CREATE INDEX table_facts_index02 ON table_facts (table_code);
CREATE INDEX table_facts_index03 ON table_facts (fact_id);

CREATE SEQUENCE seq_message;

CREATE TABLE message (
    message_id number(19) NOT NULL,
    report_id number(19),
    sequence_in_report int,
    message_code varchar2(256),
    message_level varchar2(256),
    value varchar2(4000),
    PRIMARY KEY (message_id)
);
CREATE INDEX message_index02 ON message (report_id, sequence_in_report);

CREATE TRIGGER message_insert_trigger BEFORE INSERT ON message
  FOR EACH ROW
    BEGIN
       SELECT seq_message.NEXTVAL INTO :NEW.message_id from dual;
    END;
/
CREATE TABLE message_reference (
    message_id number(19) NOT NULL,
    object_id number(19) NOT NULL -- may be any table with 'seq_object' id
);
CREATE INDEX message_reference_index01 ON message_reference (message_id);
CREATE UNIQUE INDEX message_reference_index02 ON message_reference (message_id, object_id);
/
CREATE SEQUENCE seq_industry;

CREATE TABLE industry (
    industry_id number(19) NOT NULL,
    industry_classification varchar2(16),
    industry_code integer,
    industry_description varchar2(512),
    depth integer,
    parent_id number(19),
    PRIMARY KEY (industry_id)
);

--
-- Data for Name: industry_level; Type: TABLE DATA; Schema: public; Owner: postgres
--

CREATE SEQUENCE seq_industry_level;
CREATE TABLE industry_level (
    industry_level_id number(19) NOT NULL,
    industry_classification varchar2(16),
    ancestor_id number(19),
    ancestor_code integer,
    ancestor_depth integer,
    descendant_id number(19),
    descendant_code integer,
    descendant_depth integer,
    PRIMARY KEY (industry_level_id)
);

CREATE SEQUENCE seq_industry_structure;
CREATE TABLE industry_structure (
    industry_structure_id number(19),
    industry_classification varchar2(8) NOT NULL,
    depth integer NOT NULL,
    level_name varchar2(32),
    PRIMARY KEY (industry_structure_id)
);
