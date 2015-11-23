REPORT  Z_HELLO_PARALLEL_CURSOR.


TYPES: ty_t_vbak TYPE STANDARD TABLE OF vbak.
DATA: it_vbak TYPE ty_t_vbak .
*
TYPES: ty_t_vbap TYPE STANDARD TABLE OF vbap.
DATA: it_vbap TYPE ty_t_vbap.
*
FIELD-SYMBOLS: <lfs_vbak> LIKE LINE OF it_vbak,
               <lfs_vbap> LIKE LINE OF it_vbap.
*
* necessary data selection
SELECT * FROM vbak
  INTO TABLE it_vbak.

SELECT * FROM vbap
  INTO TABLE it_vbap
  FOR ALL ENTRIES IN it_vbak
  WHERE vbeln = it_vbak-vbeln.


DATA: lv_start_time TYPE timestampl,
      lv_end_time   TYPE timestampl,
      lv_diff       TYPE timestampl.
DATA: lv_tabix TYPE i.





*
*...... Normal Nested Loop .................................
* Get the Start Time
GET TIME STAMP FIELD lv_start_time.
*
* Nested Loop
LOOP AT it_vbak ASSIGNING <lfs_vbak>.
  LOOP AT it_vbap ASSIGNING <lfs_vbap>
                  WHERE vbeln = <lfs_vbak>-vbeln.
  ENDLOOP.
ENDLOOP.
*
* Get the end time
GET TIME STAMP FIELD lv_end_time.
*
* Actual time Spent:
lv_diff = lv_end_time - lv_start_time.
WRITE: /(50) 'Time Spent on Nested Loop', lv_diff.
*
CLEAR: lv_start_time, lv_end_time, lv_diff.

CLEAR it_vbap.
CLEAR it_vbak.
SELECT * FROM vbak
  INTO TABLE it_vbak.

SELECT * FROM vbap
  INTO TABLE it_vbap
  FOR ALL ENTRIES IN it_vbak
  WHERE vbeln = it_vbak-vbeln.


*
*....... Parallel Cursor with Nested Loop .......................
* Get the Start Time
GET TIME STAMP FIELD lv_start_time.
*
* Starting the Parallel Cursor
SORT: it_vbak BY vbeln,
      it_vbap BY vbeln.
LOOP AT it_vbak ASSIGNING <lfs_vbak>.
*
* Read the second internal table with BINARY SEARCH
  READ TABLE it_vbap TRANSPORTING NO FIELDS
       WITH KEY vbeln = <lfs_vbak>-vbeln
       BINARY SEARCH.
* Get the TABIX number
  lv_tabix = sy-tabix.
* Start the LOOP from the first accessed record in
* previous READ i.e. LV_TABIX
  LOOP AT it_vbap FROM lv_tabix ASSIGNING <lfs_vbap>.
*
*   End the LOOP, when there is no more record with similar key
    IF <lfs_vbap>-vbeln <> <lfs_vbak>-vbeln.
      EXIT.
    ENDIF.
*   Rest of the logic would go from here...
*
  ENDLOOP.
*
ENDLOOP.
*
* Get the end time
GET TIME STAMP FIELD lv_end_time.
*
* Actual time Spent:
lv_diff = lv_end_time - lv_start_time.
WRITE: /(50) 'Time Specnt on Parallel Cursor Nested loops:', lv_diff.
*
CLEAR: lv_start_time, lv_end_time, lv_diff.



CLEAR it_vbap.
CLEAR it_vbak.
SELECT * FROM vbak INTO TABLE it_vbak.

SELECT * FROM vbap
  INTO TABLE it_vbap
  FOR ALL ENTRIES IN it_vbak
  WHERE vbeln = it_vbak-vbeln.

*....... Parallel Cursor - 2 with Nested Loop ...................
CLEAR lv_tabix.
* Get the Start Time
GET TIME STAMP FIELD lv_start_time.
*
* Starting the Parallel Cursor
SORT: it_vbak BY vbeln,
      it_vbap BY vbeln.
lv_tabix = 1.     " Set the starting index 1
LOOP AT it_vbak ASSIGNING <lfs_vbak>.
*
* Start the nested LOOP from the index
  LOOP AT it_vbap FROM lv_tabix
                  ASSIGNING <lfs_vbap>.
*   Save index & Exit the loop, if the keys are not same
    IF <lfs_vbak>-vbeln <> <lfs_vbap>-vbeln.
      lv_tabix = sy-tabix.
      EXIT.
    ENDIF.
*   Rest of the logic would go from here...
*
  ENDLOOP.
ENDLOOP.
*
* Get the end time
GET TIME STAMP FIELD lv_end_time.
*
* Actual time Spent:
lv_diff = lv_end_time - lv_start_time.
WRITE: /(50) 'Time Spent on Parallel Cursor 2 Nested loops', lv_diff.
CLEAR: lv_start_time, lv_end_time, lv_diff.
