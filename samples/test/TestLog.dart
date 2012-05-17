//Sample Code: Layout Demostration

#import('dart:html');

#import('../../client/app/app.dart');
#import('../../client/view/view.dart');
#import('../../client/util/util.dart');

class TestLog extends Activity {

	void onCreate_() {
		log("Started");
		int count = 0;
		Button btn = new Button("Click Me!");
		btn.on.click.add((event) {
			log("Clicked ${++count}");
		});
		rootView.appendChild(btn);
	}
}

void main() {
	new TestLog().run();
}
