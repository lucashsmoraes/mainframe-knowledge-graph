// Schema do Knowledge Graph - Mainframe
// Executar no Neo4j Browser (http://localhost:7474)

// =============================================
// CONSTRAINTS (garantem unicidade)
// =============================================

CREATE CONSTRAINT program_name IF NOT EXISTS
  FOR (p:Program) REQUIRE p.name IS UNIQUE;

CREATE CONSTRAINT table_name IF NOT EXISTS
  FOR (t:Table) REQUIRE t.name IS UNIQUE;

CREATE CONSTRAINT copybook_name IF NOT EXISTS
  FOR (c:Copybook) REQUIRE c.name IS UNIQUE;

CREATE CONSTRAINT consumer_name IF NOT EXISTS
  FOR (c:Consumer) REQUIRE c.name IS UNIQUE;

CREATE CONSTRAINT job_name IF NOT EXISTS
  FOR (j:Job) REQUIRE j.name IS UNIQUE;

CREATE CONSTRAINT document_id IF NOT EXISTS
  FOR (d:Document) REQUIRE d.doc_id IS UNIQUE;

// =============================================
// INDEXES (buscas rápidas)
// =============================================

CREATE INDEX program_type IF NOT EXISTS
  FOR (p:Program) ON (p.type);

CREATE INDEX table_schema IF NOT EXISTS
  FOR (t:Table) ON (t.schema);

CREATE INDEX consumer_criticidade IF NOT EXISTS
  FOR (c:Consumer) ON (c.criticidade);
