# dementia-index
Code for construction of the dementia index

## Pipeline

1. `00.setup.r` - file paths, libraries, code lists and helper functions.
2. `01*.r` - extract and clean each data source (SMR, NRS deaths, care home
   census, PDS, social care, PIS). Each source keeps the CHI number as
   recorded in that source.
3. `02.Compile CHI list.r` - compiles a de-duplicated list of all CHI numbers
   across the sources (including the all-deaths extract) and saves it as a
   csv to send to the CHI team.
4. `03.Link sources.r` - joins the sources together and builds the index.

## CHI to UPI resolution

A patient can hold several different CHI numbers over time. Before linking,
every CHI is revised to its most recent version (the UPI) so that records
for the same person link together across sources.

We no longer have access to the UPIP database, so this can no longer be done
in-house. Instead, we have agreed the following process with the CHI team:

1. Run `02.Compile CHI list.r`. This saves a csv of all CHI numbers to
   `<data folder>/lookups/chi_list_for_chi_team_<date>.csv`.
2. Send this list to the CHI team. They return the same list with a `upi`
   column added containing the UPI for each CHI.
3. Save the returned file as `<data folder>/lookups/chi_upi_lookup.csv`
   (columns: `chi`, `upi`).
4. Run `03.Link sources.r`. The lookup is applied to every source before
   linking; CHIs with no match in the lookup are kept unchanged, and
   duplicate records created where several CHIs map to the same UPI are
   removed.
