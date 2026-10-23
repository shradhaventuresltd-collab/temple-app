# Deity synonym validation

Research Pavi (research teammate) validated the groups and the child-to-parent one-way rules on Oct 23, 2026. The searchable copy is `lib/utils/deity_synonyms.dart`. Spellings are stored as people type them. Search folds `sh`/`s`, `th`/`t`, `ee`/`i`, `oo`/`u`, `aa`/`a`, `w`/`v`, and doubled consonants before lookup.

## Rules from Pavi

- Expansion is one-way, from the specific form to its parent.
- Jagannath, Vithoba and Vitthal go one-way into Krishna.
- Rama and Krishna go one-way into Vishnu.
- Venkateswara/Balaji is its own group, one-way into Vishnu.
- Nataraja goes one-way into Shiva.
- Ayyanar goes one-way into Ayyappa, and Ayyappa stays separate from Murugan.
- Devi is an umbrella over Durga, Parvati, Kali and Lakshmi, which are distinct goddesses, not synonyms of each other.
- Vaishno Devi goes one-way into Durga.
- Lakshmi and Hanuman were added as new groups.
- Nothing in the original list belonged to the wrong deity.

Names inside a group are bidirectional with the group name and with each other. A one-way name is found when its group is searched, and searching that name does not return the rest of the group. A parent link is the other one-way edge: searching the parent returns the child group, and searching the child does not return the parent or the parent's other children.

The group name is matched as well as the spellings below. Govinda is listed under both Krishna and Venkateswara, so that search returns both groups.

## Added after Pavi's validation (engineering decision, Oct 23, 2026; pending research confirmation)

Shrine and place names are one-way. A search for the shrine returns that shrine. A search for the deity still finds it. Goddess forms such as Meenakshi, Kamakshi, Annapurna, Chamundi, and Chamundeshwari stay bidirectional, because they name the deity rather than one shrine.

Pavi's one-way names (Jagannath, Vithoba, Vitthal, Nataraja, Ayyanar, and Vaishno Devi) are unchanged. These names were reclassified from two-way synonyms to one-way:

- Somnath
- Mahakal
- Guruvayurappan
- Guruvayoorappan
- Shrinathji
- Udupi Krishna
- Padmanabhaswamy
- Ranganathaswamy
- Varadaraja
- Tirupati Balaji
- Palani Andavar
- Kanaka Durga
- Siddhivinayak

## Krishna

Parent: Vishnu.

Two-way: Krishnan, Kannan, Krishn, Kanha, Gopal, Gopala, Govinda.

One-way: Jagannath, Vithoba, Vitthal, Guruvayurappan, Guruvayoorappan, Shrinathji, Udupi Krishna.

## Vishnu

Two-way: Narayana, Narayanan, Perumal, Padmanabha, Ranganatha, Ranganathar, Narasimha, Lakshmi Narasimha.

One-way: Padmanabhaswamy, Ranganathaswamy, Varadaraja.

Children, one-way into Vishnu: Rama, Krishna, Venkateswara.

## Venkateswara

Parent: Vishnu.

Two-way: Venkateshwara, Venkateswara Swamy, Venkatachalapathy, Srinivasa, Balaji, Yedukondalavadu, Thimmappa, Govinda.

One-way: Tirupati Balaji.

## Rama

Parent: Vishnu. No extra spellings.

## Shiva

Two-way: Siva, Sivan, Shiv, Shivan, Mahadev, Mahadeva, Mahadevar, Eswara, Eshwara, Ishwar, Iswaran, Easwaran, Shankar, Shankara, Sambhu, Bholenath, Rudra, Mahesh, Linga, Lingeswara.

One-way: Nataraja, Somnath, Mahakal.

## Murugan

Two-way: Subramanya, Subrahmanya, Subramaniam, Subramanian, Kartikeya, Karthikeya, Kartik, Skanda, Kanda, Kandaswamy, Shanmukha, Arumugam, Velan, Senthil, Kumaraswamy, Swaminatha, Dandayudhapani.

One-way: Palani Andavar.

Ayyappa is a separate group.

## Ayyappa

Two-way: Ayyappan, Ayyappa Swamy, Sastha, Shasta, Dharma Sastha, Manikandan, Hariharaputra.

One-way: Ayyanar.

## Devi

Umbrella. Durga, Parvati, Kali, and Lakshmi are children, not synonyms of each other.

Two-way: Amman, Amma, Ambal, Ambika, Bhagavathi, Bhagavati, Mata, Maa, Shakti.

## Durga

Parent: Devi.

Two-way: Durgamma, Chamundi, Chamundeshwari.

One-way: Vaishno Devi, Kanaka Durga.

## Parvati

Parent: Devi.

Two-way: Uma, Gauri, Meenakshi, Kamakshi, Annapurna.

## Kali

Parent: Devi.

Two-way: Kaali, Kalika, Mahakali, Bhadrakali, Kali Maa.

## Lakshmi

Parent: Devi. Added as a new group.

Two-way: Laxmi, Mahalakshmi, Mahalaxmi, Thayar.

## Ganesha

Two-way: Ganesh, Ganesan, Vinayaka, Vinayak, Vinayagar, Ganapati, Ganapathi, Ganapathy, Pillaiyar, Pillayar, Vigneshwara, Gajanan, Ganpati.

One-way: Siddhivinayak.

## Hanuman

Added as a new group.

Two-way: Anjaneya, Anjaneyar, Anjaneyulu, Maruti, Bajrangbali, Hanumanji.
