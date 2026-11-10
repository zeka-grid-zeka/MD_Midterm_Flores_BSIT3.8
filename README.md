# Community Learning Center Management System

Name: Karlo Miguel Flores
Section: BSIT 3.8
Course: Mobile Development, Midterm Laboratory Examination

## Description

A console application written in Dart that manages a community learning center. It registers learning resources (books and online courses) and participants, processes borrowing and returning transactions with fee computation, and displays organized records.

## Implemented Features

The program shows a titled menu with eight actions: add a learning resource, register a participant, borrow a resource, return a resource, view resources, view participants, view the transaction log, and exit. The menu loops until the user chooses 0.

Resources and participants receive automatic IDs (R001, P001, and so on). Borrowing reduces the available copies of a resource, and returning it restores them and charges a fee based on the number of days borrowed. Books are charged per day, while online courses are charged per day with a cap of 7 billed days.

All input is validated. Empty text, non-numeric values, out of range numbers, unknown IDs, unavailable copies, and invalid menu choices produce a clear message and the program keeps running.

## OOP Design

The abstract class CenterRecord is the parent of all records. It has private fields, getters, a validated name setter, and the abstract methods category and describe. The abstract class LearningResource extends it and is specialized by Book and OnlineCourse, which override computeFee and describe. Participant also extends CenterRecord with its own describe. The mixin Timestamped adds creation time tracking to every record. The CenterManager class stores resources in a Map keyed by ID, participants in a List, and transactions in a List. Polymorphism is shown when allRecords returns a list of CenterRecord objects and describe is called on each one.

## Sample Test Scenarios

Scenario 1, normal flow: add a book named "Dart Basics" with 2 copies and a fee of 5, register a participant named "Ana", borrow R001 as P001, then return it after 3 days. The program charges a fee of 15.00 and the log shows both transactions.

Scenario 2, invalid input: at the menu enter 9 and then abc. The program prints an invalid choice message each time and shows the menu again. When adding a resource, entering "abc" for copies prompts again instead of crashing.

Scenario 3, error condition: try to borrow a resource whose copies are all taken, or use an ID that does not exist such as R999. The program prints an error message and returns to the menu.

Scenario 4, polymorphic fee: add an online course with a fee of 10, borrow it, and return it after 10 days. The fee is 70.00 because only 7 days are billed.

## How to Run

Option 1, DartPad: open dartpad.dev, switch to a Dart console project, paste the contents of main.dart, and click Run.

Option 2, local Dart SDK: install the Dart SDK, open a terminal in the project folder, and run the following command.

```
dart run main.dart
```
