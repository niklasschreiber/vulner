pub extern crate htmlescape;

fn main() {
	let mut doc: DOMTree<String> = html!(
		<html>
			<head>
				<title>"Hello Kitty"</title>
				<meta name=Metadata::Author content="Not Sanrio Co., Ltd"/>
			</head>
			<body>
				<h1>"Hello Kitty"</h1>
				<p class="official">
					"She is not a cat. She is a human girl."
				</p>
				{ (0..3).map(|_| html!(
					<p class="emphasis">
						"Her name is Kitty White."
					</p>
				)) }
				<p class="citation-needed">
					"We still don't know how she eats."
				</p>
			</body>
		</html>
	);
	let doc_str = doc.to_string();
}