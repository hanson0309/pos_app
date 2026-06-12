class MalaysianState {
  final String code;
  final String name;

  const MalaysianState({required this.code, required this.name});
}

/// LHDN MyInvois state codes (2-digit).
const kMalaysianStates = [
  MalaysianState(code: '01', name: 'Johor'),
  MalaysianState(code: '02', name: 'Kedah'),
  MalaysianState(code: '03', name: 'Kelantan'),
  MalaysianState(code: '04', name: 'Melaka'),
  MalaysianState(code: '05', name: 'Negeri Sembilan'),
  MalaysianState(code: '06', name: 'Pahang'),
  MalaysianState(code: '07', name: 'Pulau Pinang'),
  MalaysianState(code: '08', name: 'Perak'),
  MalaysianState(code: '09', name: 'Perlis'),
  MalaysianState(code: '10', name: 'Selangor'),
  MalaysianState(code: '11', name: 'Terengganu'),
  MalaysianState(code: '12', name: 'Sabah'),
  MalaysianState(code: '13', name: 'Sarawak'),
  MalaysianState(code: '14', name: 'Kuala Lumpur'),
  MalaysianState(code: '15', name: 'Labuan'),
  MalaysianState(code: '16', name: 'Putrajaya'),
];

String malaysianStateName(String code) {
  for (final state in kMalaysianStates) {
    if (state.code == code) return state.name;
  }
  return code;
}
