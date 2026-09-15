import 'package:integration_test/integration_test.dart';
import '../test/support/conversation_task_acceptance_flow.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final observations = <Map<String, num>>[];
  conversationTaskAcceptanceTests(
    record: (metrics) {
      observations.add(metrics);
      binding.reportData = {'conversationTaskObservations': observations};
    },
  );
}
