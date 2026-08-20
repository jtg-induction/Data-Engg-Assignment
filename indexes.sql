CREATE INDEX IF NOT EXISTS idx_sales_dealernumber ON sales(dealernumber);

CREATE INDEX IF NOT EXISTS idx_parts_part_number ON parts(part_number);

CREATE INDEX IF NOT EXISTS idx_entity_dealernumber ON entity(dealernumber);

CREATE INDEX IF NOT EXISTS idx_objectives_dealer ON objectives(dealer);

CREATE INDEX IF NOT EXISTS idx_penetration_dealer ON penetration(dealer);

CREATE INDEX IF NOT EXISTS idx_entity_region ON entity(region);

CREATE INDEX IF NOT EXISTS idx_objective_sales ON objectives(sales_obj);

CREATE INDEX idx_sales_dealer_data ON sales(dealernumber, calendardate);

CREATE INDEX IF NOT EXISTS idx_objectives_dealer_month ON objectives(dealer, MONTH);