# Implementation Plan

- [ ] 1. Write bug condition exploration test for education level display
  - **Property 1: Bug Condition** - Education Level Not Displayed in Job Details
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: For deterministic bugs, scope the property to the concrete failing case(s) to ensure reproducibility
  - Test that when a job has educationLevel field set (e.g., "Ali", "Orta"), the job_detail_screen displays it in the "Detallar" section with label "Təhsil"
  - Test that when educationLevel is null or empty, it displays "Vacib deyil"
  - The test assertions should match the Expected Behavior Properties from design
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found to understand root cause (e.g., "educationLevel='Ali' is not displayed in Details section")
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 2.1, 2.2, 2.3_

- [ ] 2. Write bug condition exploration test for working hours time picker
  - **Property 1: Bug Condition** - Working Hours Manual Input Instead of Time Picker
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: For deterministic bugs, scope the property to the concrete failing case(s) to ensure reproducibility
  - Test that create_job_screen uses time picker dialogs (showTimePicker) instead of TextFormField for working hours input
  - Test that selected times are automatically formatted as "HH:mm - HH:mm"
  - The test assertions should match the Expected Behavior Properties from design
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found to understand root cause (e.g., "Working hours input is TextFormField, not time picker")
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 2.4, 2.5, 2.6, 2.7, 2.8_

- [ ] 3. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Existing Job Creation and Display Flows
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-buggy inputs (other job fields like title, category, salary, location, benefits, requirements)
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements
  - Property-based testing generates many test cases for stronger guarantees
  - Test that job title input and display work the same way after fix
  - Test that salary input works the same way after fix
  - Test that location selection works the same way after fix
  - Test that benefits selection works the same way after fix
  - Test that job type selection works the same way after fix
  - Test that other detail fields (company name, city, salary, etc.) display the same way after fix
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9_

- [ ] 4. Fix for education level display and working hours time picker

  - [ ] 4.1 Add education level display to job_detail_screen.dart
    - Open `lib/features/jobs/presentation/pages/job_detail_screen.dart`
    - Locate the "Detallar" section (around line 550-585) where _DetailRow widgets are used
    - Add a new _DetailRow for education level after the experienceLevel row (if exists) or before workingHours row
    - Use icon: `Icons.school_rounded`, label: `'Təhsil'`, value: `currentJob.educationLevel ?? 'Vacib deyil'`
    - Ensure the row is always displayed (no conditional if statement needed)
    - _Bug_Condition: isBugCondition1(input) where input.job.educationLevel IS NOT NULL AND NOT displayedInDetailsSection(input.job.educationLevel)_
    - _Expected_Behavior: educationLevel SHALL be displayed in "Detallar" section with label "Təhsil" and value from educationLevel field or "Vacib deyil" if null_
    - _Preservation: Other detail rows (company, city, district, address, workingHours, date) SHALL remain unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 3.4, 3.5_

  - [ ] 4.2 Replace working hours TextFormField with time picker in create_job_screen.dart
    - Open `lib/features/jobs/presentation/pages/create_job_screen.dart`
    - Add two new state variables: `TimeOfDay? _startTime` and `TimeOfDay? _endTime`
    - Locate the working hours TextFormField (around line 860-870)
    - Replace TextFormField with a custom UI showing two buttons: "Başlanğıc saatı" and "Bitmə saatı"
    - Each button should display the selected time or a placeholder (e.g., "Seçin")
    - When tapped, each button should call `showTimePicker` with appropriate initial time
    - Add helper method `_updateWorkingHours()` that formats selected times as "HH:mm - HH:mm" and updates `_workingHoursController.text`
    - Add method `_pickTime(bool isStartTime)` that opens time picker and updates state
    - In `initState`, parse existing `workingHours` string (if editing job) and populate `_startTime` and `_endTime`
    - Ensure the UI shows the formatted time range below the buttons
    - _Bug_Condition: isBugCondition2(input) where input.workingHoursInputType == "TextFormField" AND NOT usesTimePicker(input.workingHoursInput)_
    - _Expected_Behavior: workingHours input SHALL use time picker dialogs and automatically format as "HH:mm - HH:mm"_
    - _Preservation: Other job creation fields (title, category, salary, location, benefits, requirements) SHALL remain unchanged_
    - _Requirements: 2.4, 2.5, 2.6, 2.7, 2.8, 3.1, 3.2, 3.3_

  - [ ] 4.3 Verify bug condition exploration tests now pass
    - **Property 1: Expected Behavior** - Education Level Displayed and Time Picker Used
    - **IMPORTANT**: Re-run the SAME tests from tasks 1 and 2 - do NOT write new tests
    - The tests from tasks 1 and 2 encode the expected behavior
    - When these tests pass, it confirms the expected behavior is satisfied
    - Run bug condition exploration tests from steps 1 and 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms bugs are fixed)
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

  - [ ] 4.4 Verify preservation tests still pass
    - **Property 2: Preservation** - Existing Job Flows Unchanged
    - **IMPORTANT**: Re-run the SAME tests from task 3 - do NOT write new tests
    - Run preservation property tests from step 3
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm all tests still pass after fix (no regressions in other job fields)
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9_

- [ ] 5. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
