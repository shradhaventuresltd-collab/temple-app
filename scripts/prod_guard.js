/**
 * Shared guards for scripts that can write production Firestore.
 * Dry-run is the default in each caller. These checks run only for --apply.
 */

export function assertNotCi() {
  if (
    process.env.CI ||
    process.env.GITHUB_ACTIONS ||
    process.env.GITHUB_WORKFLOW
  ) {
    throw new Error(
      "Refusing to write Firestore or Storage from CI. Deployer applies after merge, from a terminal.",
    );
  }
}

export function assertExplicitProject(project) {
  if (typeof project !== "string" || project.trim() === "") {
    throw new Error(
      "Prod apply needs an explicit --project <firebase-project-id>. There is no default project.",
    );
  }
  return project.trim();
}

/**
 * Interactive confirm. Requires a TTY. The operator must type the project id.
 * @param {string} project
 */
export async function confirmProject(project) {
  assertNotCi();
  const id = assertExplicitProject(project);
  if (!process.stdin.isTTY) {
    throw new Error(
      "Refusing to write without a confirm prompt. Run this in a terminal and type the project id when asked.",
    );
  }
  const { createInterface } = await import("node:readline/promises");
  const rl = createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  try {
    const answer = (
      await rl.question(
        `This writes production Firestore for project "${id}".\nType the project id to continue: `,
      )
    ).trim();
    if (answer !== id) {
      throw new Error("Confirmation did not match the project id. No write.");
    }
  } finally {
    rl.close();
  }
  return id;
}
