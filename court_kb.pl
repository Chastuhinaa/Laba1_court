:- encoding(utf8).
% =====================================================================
% БАЗА ЗНАНЬ: Судова система України (суди, судді, справи, учасники)
% =====================================================================

% --- 1. Базові класи онтології ---
class(person).
class(organization).
class(court).
class(legal_case).

% --- 2. Таксономія понять (ієрархія класів) ---
subclass(legal_professional, person).
subclass(judge, legal_professional).
subclass(lawyer, legal_professional).
subclass(prosecutor, legal_professional).
subclass(citizen, person).
subclass(company, organization).

subclass(local_court, court).
subclass(appellate_court, court).
subclass(supreme_court, court).

subclass(civil_case, legal_case).
subclass(criminal_case, legal_case).
subclass(administrative_case, legal_case).

% --- 3. Онтологічні обмеження (несумісні класи) ---
% Суддя не може бути адвокатом чи прокурором (несумісність посад)
disjoint(judge, lawyer).
disjoint(judge, prosecutor).
disjoint(lawyer, prosecutor).
% Справа належить лише до одного виду судочинства
disjoint(civil_case, criminal_case).
disjoint(civil_case, administrative_case).
disjoint(criminal_case, administrative_case).

% --- 4. Екземпляри (конкретні сутності) ---
% Судді
instance(kovalenko, judge).
instance(marchenko, judge).
instance(tkachenko, judge).
% Адвокати та прокурор
instance(bondar, lawyer).
instance(savchenko, lawyer).
instance(hrytsenko, prosecutor).
% Громадяни та юридична особа
instance(melnyk, citizen).
instance(shevchuk, citizen).
instance(lysenko, citizen).
instance(agro_tech, company).
% Навмисна помилка для перевірки disjoint
instance(moroz, judge).
instance(moroz, lawyer).

% Суди
instance(pecherskyi_court, local_court).
instance(halytskyi_court, local_court).
instance(kyiv_appeal_court, appellate_court).
instance(lviv_appeal_court, appellate_court).
instance(supreme_court_ua, supreme_court).

% Справи
instance(case_101, civil_case).
instance(case_202, criminal_case).
instance(case_303, administrative_case).
instance(case_404, civil_case).

% --- 5. Ієрархічні зв'язки між інстанціями (куди оскаржується рішення) ---
appeal_to(pecherskyi_court, kyiv_appeal_court).
appeal_to(halytskyi_court, lviv_appeal_court).
appeal_to(kyiv_appeal_court, supreme_court_ua).
appeal_to(lviv_appeal_court, supreme_court_ua).

% --- 6. Мереологічні зв'язки (структура Верховного Суду) ---
part_of(grand_chamber, supreme_court_ua).
part_of(cassation_civil_court, supreme_court_ua).
part_of(cassation_criminal_court, supreme_court_ua).
part_of(cassation_admin_court, supreme_court_ua).
part_of(first_civil_chamber, cassation_civil_court).

% --- 7. Асоціативні зв'язки ---
% Місце роботи судді
works_in(kovalenko, pecherskyi_court).
works_in(tkachenko, halytskyi_court).
works_in(marchenko, kyiv_appeal_court).

% Розгляд справи: справа, суд, суддя-доповідач
considered_by(case_101, pecherskyi_court, kovalenko).
considered_by(case_202, halytskyi_court, tkachenko).
considered_by(case_303, pecherskyi_court, kovalenko).
considered_by(case_404, pecherskyi_court, tkachenko).   % навмисна помилка

% Учасники справи та їхня процесуальна роль
participant(case_101, melnyk, plaintiff).
participant(case_101, agro_tech, defendant).
participant(case_101, bondar, representative).
participant(case_202, shevchuk, accused).
participant(case_202, savchenko, defender).
participant(case_202, hrytsenko, public_prosecutor).
participant(case_303, lysenko, plaintiff).
participant(case_303, bondar, representative).
participant(case_404, shevchuk, plaintiff).
participant(case_404, melnyk, defendant).

% Родинні зв'язки (важливі для відводу судді)
relative(kovalenko, lysenko).

% Ухвалені рішення
decision(case_101, claim_satisfied).
decision(case_202, guilty_verdict).

% --- 8. Атрибути ---
has_attribute(case_101, claim_amount, 250000).
has_attribute(case_404, claim_amount, 1500000).
has_attribute(case_202, criminal_code_article, 185).
has_attribute(case_101, filing_year, 2025).
has_attribute(case_202, filing_year, 2025).
has_attribute(case_303, filing_year, 2026).
has_attribute(case_404, filing_year, 2026).
has_attribute(kovalenko, experience_years, 12).
has_attribute(marchenko, experience_years, 20).
has_attribute(tkachenko, experience_years, 3).

% =====================================================================
% ЛОГІЧНІ ПРАВИЛА ТА ВИВЕДЕННЯ НОВИХ ЗНАНЬ
% =====================================================================

% Правило 1: Транзитивне замикання ієрархії класів
subclass_trans(Sub, Super) :-
    subclass(Sub, Super).
subclass_trans(Sub, Super) :-
    subclass(Sub, Mid),
    subclass_trans(Mid, Super).

% Правило 2: Успадкування належності до класу (is-a)
is_a(Entity, Class) :-
    instance(Entity, Class).
is_a(Entity, Class) :-
    instance(Entity, DirectClass),
    subclass_trans(DirectClass, Class).

% Правило 3: Транзитивний ланцюг судових інстанцій
higher_instance(Lower, Higher) :-
    appeal_to(Lower, Higher).
higher_instance(Lower, Higher) :-
    appeal_to(Lower, Mid),
    higher_instance(Mid, Higher).

% Правило 4: Транзитивне входження підрозділу до складу суду
located_in(Unit, Whole) :-
    part_of(Unit, Whole).
located_in(Unit, Whole) :-
    part_of(Unit, Mid),
    located_in(Mid, Whole).

% Правило 5: До яких судів можна оскаржити рішення у справі
can_appeal_to(Case, Court) :-
    considered_by(Case, FirstCourt, _),
    higher_instance(FirstCourt, Court).

% Правило 6: Категорія судді за стажем (зелене відтинання)
judge_category(Judge, senior) :-
    has_attribute(Judge, experience_years, Y),
    Y >= 10, !.
judge_category(Judge, junior) :-
    has_attribute(Judge, experience_years, Y),
    Y < 10.

% Правило 7: Стан справи (червоне відтинання)
case_state(Case, State) :-
    decision(Case, _), !,
    State = decided.
case_state(_Case, pending).

% Правило 8: Велика цивільна справа (ціна позову >= 1 000 000 грн)
high_value_claim(Case) :-
    is_a(Case, civil_case),
    has_attribute(Case, claim_amount, Amount),
    Amount >= 1000000.

% Правило 9: Справа без професійного захисника чи представника (\+)
lacks_lawyer(Case) :-
    is_a(Case, legal_case),
    \+ ( participant(Case, L, _), is_a(L, lawyer) ).

% Правило 10: Клієнти одного адвоката (пари без дублювання, @<)
same_lawyer_clients(Client1, Client2, Lawyer) :-
    instance(Lawyer, lawyer),
    participant(Case1, Lawyer, _),
    participant(Case1, Client1, plaintiff),
    participant(Case2, Lawyer, _),
    participant(Case2, Client2, plaintiff),
    Client1 @< Client2.

% Правило 11: Підстава для відводу судді (конфлікт інтересів)
recusal_ground(Judge, Case, Person) :-
    considered_by(Case, _, Judge),
    participant(Case, Person, _),
    relative(Judge, Person).

% =====================================================================
% ПЕРЕВІРКИ УЗГОДЖЕНОСТІ МОДЕЛІ
% =====================================================================

% Правило 12: Порушення аксіоми несумісності класів
inconsistent_entity(Entity, C1, C2) :-
    instance(Entity, C1),
    instance(Entity, C2),
    C1 \= C2,
    disjoint(C1, C2).

% Правило 13: Суддя розглядає справу не у своєму суді
wrong_court_assignment(Case, Judge, Court) :-
    considered_by(Case, Court, Judge),
    \+ works_in(Judge, Court).
