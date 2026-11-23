var points = 0
var pointDisplay = 0 
var content = 0
window.addEventListener('message', event => {

    if (event.data.transactionType !== undefined && event.data.transactionType === "displayPoints") {
        const data = event.data
        show(parseInt(data.points), data.content) 
    }
})

function show(pointsToAdd, contentToAdd) {
    const elPoints = document.getElementById('points'), elContent = document.getElementById('content')
    points = points + pointsToAdd
    pointDisplay = "+" + points
    content = contentToAdd
    elPoints.innerHTML = pointDisplay, elContent.innerHTML = content
    fade()
}

var timeout;
function fade() {
    if (timeout) clearTimeout(timeout)
    const elPoints = document.getElementById('points'), elContent = document.getElementById('content')
    elContent.classList.add('fade')
    elPoints.classList.add('glow')
    timeout = setTimeout(() => {
        elContent.classList.toggle('fade')
        elPoints.classList.toggle('glow')
        points = 0
    }, 1400)
}